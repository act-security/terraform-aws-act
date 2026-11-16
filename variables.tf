variable "role_name" {
  description = "Name of the IAM role, `role_name` from the Act onboarding values."
  type        = string
}

variable "external_id" {
  description = "The external ID the role's trust policy requires, `external_id` from the Act onboarding values. Not a secret."
  type        = string
}

variable "act_principal_arn" {
  description = "The Act principal the role trusts, `act_principal_arn` from the Act onboarding values."
  type        = string
}

variable "deprecated_principal_arns" {
  description = "Act principals being retired that the role keeps trusting during a rotation, `deprecated_principal_arns` from the Act onboarding values."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "enable_eks_cluster_access" {
  description = "Let Act create a view-only EKS access entry for the role so it can scan Kubernetes inside EKS clusters."
  type        = bool
  default     = true
  nullable    = false
}

variable "cloudtrail_bucket_name" {
  description = "The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket."
  type        = string
  default     = "*"
  nullable    = false
}

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary to attach to the role."
  type        = string
  default     = null
}

variable "tags" {
  description = "AWS tags for the role and its policies."
  type        = map(string)
  default     = {}
  nullable    = false
}
