provider "act" {}

provider "aws" {
  region = var.region
}

module "act" {
  source = "../../modules/organization"

  name                    = var.name
  call_as                 = "DELEGATED_ADMIN"
  organizational_unit_ids = ["ou-ab12-11111111", "ou-ab12-22222222"]
}
