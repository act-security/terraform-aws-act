variable "partition" {
  description = "The AWS partition the policies are for, such as `aws`."
  type        = string
}

variable "account_id" {
  description = "The AWS account the policies are for."
  type        = string
}

variable "role_name" {
  description = "Name of the role the policies are attached to."
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket."
  type        = string
  default     = "*"
  nullable    = false

  validation {
    condition     = can(regex("^(\\*|[a-z0-9][a-z0-9.-]{1,61}[a-z0-9])$", var.cloudtrail_bucket_name))
    error_message = "cloudtrail_bucket_name must be * or an S3 bucket name."
  }
}

variable "enable_eks_cluster_access" {
  description = "Include the permissions Act needs to create a view-only EKS access entry for the role."
  type        = bool
  default     = false
  nullable    = false
}
