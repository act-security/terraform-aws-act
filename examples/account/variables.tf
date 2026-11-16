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

variable "permission_groups" {
  description = "The permission groups to grant, for example `{ kubernetes = {}, cloudtrail_logs = { bucket = \"org-trail-logs\" } }`. Null grants every group."
  type        = any
  default     = null
}
