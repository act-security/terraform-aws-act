provider "aws" {
  region = var.region
}

module "act" {
  source = "../.."

  role_name         = var.role_name
  external_id       = var.external_id
  act_principal_arn = var.act_principal_arn
}
