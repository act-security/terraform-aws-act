data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

module "permissions" {
  source = "./modules/permissions"

  partition                 = data.aws_partition.current.partition
  account_id                = data.aws_caller_identity.current.account_id
  role_name                 = var.role_name
  permission_groups         = var.permission_groups
  enable_eks_cluster_access = var.enable_eks_cluster_access
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
}

locals {
  trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { AWS = concat([var.act_principal_arn], var.deprecated_principal_arns) }
        Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
      },
    ]
  })
}

resource "aws_iam_role" "act" {
  name                 = var.role_name
  description          = "Read-only role Act assumes with an external ID"
  assume_role_policy   = local.trust_policy
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge(var.tags, { DeploymentVersion = module.permissions.deployment_version })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(module.permissions.managed_policy_arns)

  role       = aws_iam_role.act.name
  policy_arn = each.value
}

resource "aws_iam_policy" "group" {
  for_each = module.permissions.group_policy_documents

  name        = "${var.role_name}-${each.key}"
  description = "Act read permissions: ${each.key}"
  policy      = each.value
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "group" {
  for_each = aws_iam_policy.group

  role       = aws_iam_role.act.name
  policy_arn = each.value.arn
}

resource "aws_iam_policy" "core" {
  for_each = module.permissions.core_policy_documents

  name        = "${var.role_name}-${each.key}"
  description = "Act read permissions: ${each.key}"
  policy      = each.value
  tags        = var.tags

  depends_on = [aws_iam_role_policy_attachment.group]
}

resource "aws_iam_role_policy_attachment" "core" {
  for_each = aws_iam_policy.core

  role       = aws_iam_role.act.name
  policy_arn = each.value.arn
}
