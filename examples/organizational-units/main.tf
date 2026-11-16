provider "aws" {
  region = var.region
}

module "act" {
  source = "../../modules/organization"

  deployment_id           = var.deployment_id
  role_name               = var.role_name
  external_id             = var.external_id
  act_principal_arn       = var.act_principal_arn
  organizational_unit_ids = var.organizational_unit_ids
}
