data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "this" {
  return_organization_only = local.targets_given
}

data "act_current_identity" "current" {}

locals {
  targets_given = var.root_id != null || length(var.organizational_unit_ids) > 0
  root_id       = local.targets_given ? var.root_id : one(data.aws_organizations_organization.this.roots[*].id)
  target_ids    = local.root_id == null ? var.organizational_unit_ids : toset([local.root_id])

  delegated_admin_account_ids    = var.call_as == "DELEGATED_ADMIN" ? [data.aws_caller_identity.current.account_id] : []
  stack_set_excluded_account_ids = setunion(var.excluded_account_ids, local.delegated_admin_account_ids)
}

data "act_aws_onboarding_parameters" "this" {
  organization_id = data.aws_organizations_organization.this.id

  lifecycle {
    precondition {
      condition     = var.expected_tenant_id == null || data.act_current_identity.current.tenant_id == var.expected_tenant_id
      error_message = "The act provider is authenticated to tenant ${data.act_current_identity.current.tenant_id}, not expected_tenant_id ${coalesce(var.expected_tenant_id, "-")}. Check ACT_CLIENT_ID and ACT_CLIENT_SECRET."
    }

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

module "role" {
  source = "../account-role"

  role_name                 = data.act_aws_onboarding_parameters.this.role_name
  act_principal_arn         = data.act_aws_onboarding_parameters.this.act_principal_arn
  deprecated_principal_arns = data.act_aws_onboarding_parameters.this.deprecated_principal_arns
  external_id               = data.act_aws_onboarding_parameters.this.external_id
  enable_eks_cluster_access = var.enable_eks_cluster_access
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  permissions_boundary_arn  = var.permissions_boundary_arn
  tags                      = var.tags
}

module "member_permissions" {
  source = "../permissions"

  partition                 = "$${AWS::Partition}"
  account_id                = "$${AWS::AccountId}"
  role_name                 = data.act_aws_onboarding_parameters.this.member_role_name
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  enable_eks_cluster_access = var.enable_eks_cluster_access
}

resource "aws_cloudformation_stack_set" "members" {
  name             = "ActSecurity-Connector-${data.act_aws_onboarding_parameters.this.deployment_id}"
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

resource "act_aws_organization_deployment" "this" {
  deployment_id           = data.act_aws_onboarding_parameters.this.deployment_id
  organization_id         = data.aws_organizations_organization.this.id
  root_id                 = local.root_id
  organizational_unit_ids = local.root_id == null ? var.organizational_unit_ids : null
  excluded_account_ids    = length(var.excluded_account_ids) > 0 ? var.excluded_account_ids : null
  role_arn                = module.role.role_arn
  external_id_key_version = data.act_aws_onboarding_parameters.this.external_id_key_version
  name                    = var.name
  allowed_regions         = var.allowed_regions
  disabled_capabilities   = var.enable_eks_cluster_access ? [] : ["eks_cluster_access"]
  deletion_protection     = var.deletion_protection
  tags                    = var.act_tags

  depends_on = [module.role, aws_cloudformation_stack_set.members]
}

check "act_module_current" {
  assert {
    condition     = data.act_aws_onboarding_parameters.this.deployment_version == module.role.deployment_version
    error_message = "Act recommends role version ${data.act_aws_onboarding_parameters.this.deployment_version}; this module release deploys ${module.role.deployment_version}. Upgrade the module to grant the permissions Act expects."
  }
}

check "act_existing_deployment" {
  assert {
    condition     = data.act_aws_onboarding_parameters.this.existing_deployment == null || try(data.act_aws_onboarding_parameters.this.existing_deployment.created_via, null) == "api"
    error_message = "Organization ${data.aws_organizations_organization.this.id} already has Act deployment ${try(data.act_aws_onboarding_parameters.this.existing_deployment.id, "")}, created outside Terraform. Import it and its role instead of creating another: import { to = module.<name>.act_aws_organization_deployment.this, id = \"${try(data.act_aws_onboarding_parameters.this.existing_deployment.id, "")}\" } and import { to = module.<name>.module.role.aws_iam_role.act, id = \"${data.act_aws_onboarding_parameters.this.role_name}\" }."
  }
}
