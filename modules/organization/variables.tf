variable "name" {
  description = "The name Act shows for the deployment, 1 to 64 characters. Act picks one when it is null."
  type        = string
  default     = null
}

variable "root_id" {
  description = "The organization root, `r-...`, to cover every account. Set this or `organizational_unit_ids`. From the management account both can be left out and the module covers the root."
  type        = string
  default     = null
}

variable "organizational_unit_ids" {
  description = "The organizational units to cover, `ou-...`. Set this or `root_id`. To leave a unit out, list the others."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "excluded_account_ids" {
  description = "Member accounts Act leaves out and the StackSet skips, as 12-digit IDs."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "call_as" {
  description = "`SELF` in the management account, `DELEGATED_ADMIN` in a CloudFormation StackSets delegated administrator account."
  type        = string
  default     = "SELF"
  nullable    = false

  validation {
    condition     = contains(["SELF", "DELEGATED_ADMIN"], var.call_as)
    error_message = "call_as must be SELF or DELEGATED_ADMIN."
  }
}

variable "allowed_regions" {
  description = "The AWS regions Act scans, such as `us-east-1`. Null scans every region."
  type        = set(string)
  default     = null
}

variable "enable_eks_cluster_access" {
  description = "Let Act create a view-only EKS access entry for its roles so it can scan Kubernetes inside EKS clusters."
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
  description = "ARN of a permissions boundary to attach to the Act role in this account. Member roles get none."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "When true, Act refuses to delete the deployment and a plan that destroys it fails."
  type        = bool
  default     = true
  nullable    = false
}

variable "expected_tenant_id" {
  description = "The Act tenant this configuration must run as. The plan fails when the act provider is authenticated to another tenant."
  type        = string
  default     = null
}


variable "tags" {
  description = "AWS tags for the IAM role, policies and StackSet."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "act_tags" {
  description = "Act tags for the deployment, at most 50. They are not AWS tags."
  type        = map(string)
  default     = null
}
