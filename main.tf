data "aws_caller_identity" "current" {}

data "act_current_identity" "current" {}

data "act_aws_onboarding_parameters" "this" {
  account_id = data.aws_caller_identity.current.account_id

  lifecycle {
    precondition {
      condition     = var.expected_tenant_id == null || data.act_current_identity.current.tenant_id == var.expected_tenant_id
      error_message = "The act provider is authenticated to tenant ${data.act_current_identity.current.tenant_id}, not expected_tenant_id ${coalesce(var.expected_tenant_id, "-")}. Check ACT_CLIENT_ID and ACT_CLIENT_SECRET."
    }
  }
}

module "role" {
  source = "./modules/account-role"

  role_name                 = data.act_aws_onboarding_parameters.this.role_name
  act_principal_arn         = data.act_aws_onboarding_parameters.this.act_principal_arn
  deprecated_principal_arns = data.act_aws_onboarding_parameters.this.deprecated_principal_arns
  external_id               = data.act_aws_onboarding_parameters.this.external_id
  enable_eks_cluster_access = var.enable_eks_cluster_access
  cloudtrail_bucket_name    = var.cloudtrail_bucket_name
  permissions_boundary_arn  = var.permissions_boundary_arn
  tags                      = var.tags
}

resource "act_aws_account_deployment" "this" {
  deployment_id           = data.act_aws_onboarding_parameters.this.deployment_id
  account_id              = data.aws_caller_identity.current.account_id
  role_arn                = module.role.role_arn
  external_id_key_version = data.act_aws_onboarding_parameters.this.external_id_key_version
  name                    = var.name
  allowed_regions         = var.allowed_regions
  disabled_capabilities   = var.enable_eks_cluster_access ? [] : ["eks_cluster_access"]
  deletion_protection     = var.deletion_protection
  tags                    = var.act_tags

  depends_on = [module.role]
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
    error_message = "Account ${data.aws_caller_identity.current.account_id} already has Act deployment ${try(data.act_aws_onboarding_parameters.this.existing_deployment.id, "")}, created outside Terraform. Import it and its role instead of creating another: import { to = module.<name>.act_aws_account_deployment.this, id = \"${try(data.act_aws_onboarding_parameters.this.existing_deployment.id, "")}\" } and import { to = module.<name>.module.role.aws_iam_role.act, id = \"${data.act_aws_onboarding_parameters.this.role_name}\" }."
  }
}
