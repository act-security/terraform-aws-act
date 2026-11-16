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

variable "permission_groups" {
  description = "The permission groups to grant, each set to {}: `kubernetes`, `cloudtrail_logs` (optionally `{ bucket = \"<name>\" }` to limit log reads to that bucket) and `ai_services`. A group left out is not granted, and `{}` grants none. When set, it decides every group and the bucket, and `enable_eks_cluster_access` and `cloudtrail_bucket_name` are ignored. Null grants every group, with kubernetes following `enable_eks_cluster_access` and the bucket following `cloudtrail_bucket_name`, as the Act console does by default."
  type        = any
  default     = null

  validation {
    condition = var.permission_groups == null || try(alltrue([
      for group, settings in var.permission_groups :
      contains(["kubernetes", "cloudtrail_logs", "ai_services"], group) &&
      alltrue([for setting in keys(settings) : group == "cloudtrail_logs" && setting == "bucket"])
    ]), false)
    error_message = "permission_groups takes only kubernetes, cloudtrail_logs and ai_services, each set to {}; only cloudtrail_logs takes a bucket."
  }

  validation {
    condition     = try(var.permission_groups.cloudtrail_logs.bucket, null) == null || can(regex("^(\\*|[a-z0-9][a-z0-9.-]{1,61}[a-z0-9])$", var.permission_groups.cloudtrail_logs.bucket))
    error_message = "permission_groups.cloudtrail_logs.bucket must be * or an S3 bucket name."
  }
}

variable "enable_eks_cluster_access" {
  description = "See access inside your EKS clusters. If turned off, Act sees your EKS clusters but not the access inside them. Ignored when `permission_groups` is set."
  type        = bool
  default     = true
  nullable    = false
}

variable "cloudtrail_bucket_name" {
  description = "The S3 bucket your CloudTrail trail writes logs to. `*` lets Act read logs under `AWSLogs/` in any bucket. Ignored when `permission_groups` is set."
  type        = string
  default     = "*"
  nullable    = false

  validation {
    condition     = can(regex("^(\\*|[a-z0-9][a-z0-9.-]{1,61}[a-z0-9])$", var.cloudtrail_bucket_name))
    error_message = "cloudtrail_bucket_name must be * or an S3 bucket name."
  }
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
