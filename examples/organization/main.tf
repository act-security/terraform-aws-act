provider "act" {}

provider "aws" {
  region = var.region
}

module "act" {
  source = "../../modules/organization"

  name                 = var.name
  excluded_account_ids = ["222222222222"]
  allowed_regions      = ["us-east-1", "eu-west-1"]
}
