variable "name" {
  description = "The name Act shows for the deployment, 1 to 64 characters. Act picks one when it is null."
  type        = string
  default     = null
}

variable "allowed_regions" {
  description = "The AWS regions Act scans, such as `us-east-1`. Null scans every region."
  type        = set(string)
  default     = null
}

variable "enable_eks_cluster_access" {
  description = "Let Act create a view-only EKS access entry for its role so it can scan Kubernetes inside EKS clusters."
  type        = bool
  default     = false
  nullable    = false
}

variable "cloudtrail_bucket_name" {
  description = "The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket."
  type        = string
  default     = "*"
  nullable    = false
}

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary to attach to the Act role."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "When true, Act refuses to delete the deployment and a plan that destroys it fails."
  type        = bool
  default     = false
  nullable    = false
}

variable "expected_tenant_id" {
  description = "The Act tenant this configuration must run as. The plan fails when the act provider is authenticated to another tenant."
  type        = string
  default     = null
}


variable "tags" {
  description = "AWS tags for the IAM role and policies."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "act_tags" {
  description = "Act tags for the deployment, at most 50. They are not AWS tags."
  type        = map(string)
  default     = null
}
