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

variable "permission_groups" {
  description = "The permission groups to grant, validated by the root module. Null grants every group, with kubernetes following `enable_eks_cluster_access` and the bucket following `cloudtrail_bucket_name`."
  type        = any
  default     = null
}

variable "enable_eks_cluster_access" {
  description = "Grant the kubernetes group while `permission_groups` is null."
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "The bucket the cloudtrail_logs group reads while `permission_groups` is null."
  type        = string
  default     = "*"
}
