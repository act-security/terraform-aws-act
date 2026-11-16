terraform {
  required_version = ">= 1.5.7"

  required_providers {
    act = {
      source  = "act-security/act"
      version = ">= 0.3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
