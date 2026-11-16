variable "region" {
  description = "The AWS region the aws provider uses."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "`role_name` from the Act onboarding values."
  type        = string
}

variable "external_id" {
  description = "`external_id` from the Act onboarding values."
  type        = string
}

variable "act_principal_arn" {
  description = "`act_principal_arn` from the Act onboarding values."
  type        = string
}

variable "deployment_id" {
  description = "`deployment_id` from the Act onboarding values."
  type        = string
}

variable "organizational_unit_ids" {
  description = "The organizational units to cover. A delegated administrator cannot list the organization roots."
  type        = set(string)
}
