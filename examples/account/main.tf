provider "act" {}

provider "aws" {
  region = var.region
}

module "act" {
  source = "../.."

  name = var.name
}
