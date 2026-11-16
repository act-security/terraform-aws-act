data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

module "permissions" {
  source = "../permissions"

  partition                 = data.aws_partition.current.partition
  account_id                = data.aws_caller_identity.current.account_id
  role_name                 = var.role_name
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  enable_eks_cluster_access = var.enable_eks_cluster_access
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = concat([var.act_principal_arn], var.deprecated_principal_arns)
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "act" {
  name                 = var.role_name
  description          = "Read-only role Act assumes with an external ID"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge(var.tags, { DeploymentVersion = module.permissions.deployment_version })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(module.permissions.managed_policy_arns)

  role       = aws_iam_role.act.name
  policy_arn = each.value
}

resource "aws_iam_policy" "custom" {
  for_each = module.permissions.custom_policies

  name        = "${var.role_name}-${each.key}"
  description = "Act read permissions: ${each.key}"
  policy      = jsonencode(each.value)
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = aws_iam_policy.custom

  role       = aws_iam_role.act.name
  policy_arn = each.value.arn
}
