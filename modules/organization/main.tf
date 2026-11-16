data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "this" {
  return_organization_only = local.targets_given
}

locals {
  targets_given = var.root_id != null || length(var.organizational_unit_ids) > 0
  root_id       = local.targets_given ? var.root_id : one(data.aws_organizations_organization.this.roots[*].id)
  target_ids    = local.root_id == null ? var.organizational_unit_ids : toset([local.root_id])

  member_role_name = coalesce(var.member_role_name, var.role_name)

  delegated_admin_account_ids    = var.call_as == "DELEGATED_ADMIN" ? [data.aws_caller_identity.current.account_id] : []
  stack_set_excluded_account_ids = setunion(var.excluded_account_ids, local.delegated_admin_account_ids)
}

module "role" {
  source = "../.."

  role_name                 = var.role_name
  external_id               = var.external_id
  act_principal_arn         = var.act_principal_arn
  deprecated_principal_arns = var.deprecated_principal_arns
  enable_eks_cluster_access = var.enable_eks_cluster_access
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  permissions_boundary_arn  = var.permissions_boundary_arn
  tags                      = var.tags
}

module "member_permissions" {
  source = "../permissions"

  partition                 = "$${AWS::Partition}"
  account_id                = "$${AWS::AccountId}"
  role_name                 = local.member_role_name
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  enable_eks_cluster_access = var.enable_eks_cluster_access
}

resource "aws_cloudformation_stack_set" "members" {
  name             = "ActSecurity-Connector-${var.deployment_id}"
  description      = "Act read-only role in each member account"
  permission_model = "SERVICE_MANAGED"
  call_as          = var.call_as
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  template_body    = jsonencode(local.member_template)
  tags             = merge(var.tags, { DeploymentVersion = module.member_permissions.deployment_version })

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  managed_execution {
    active = true
  }

  lifecycle {
    precondition {
      condition     = var.root_id == null || length(var.organizational_unit_ids) == 0
      error_message = "Set root_id or organizational_unit_ids, not both."
    }

    precondition {
      condition     = length(local.target_ids) > 0
      error_message = "This account cannot list the organization roots. Set root_id or organizational_unit_ids."
    }
  }
}

resource "aws_cloudformation_stack_instances" "members" {
  stack_set_name = aws_cloudformation_stack_set.members.name
  call_as        = var.call_as
  regions        = [data.aws_region.current.region]

  deployment_targets {
    organizational_unit_ids = local.target_ids
    account_filter_type     = length(local.stack_set_excluded_account_ids) > 0 ? "DIFFERENCE" : "NONE"
    accounts                = length(local.stack_set_excluded_account_ids) > 0 ? local.stack_set_excluded_account_ids : null
  }
}
