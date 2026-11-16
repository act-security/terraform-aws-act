variable "deployment_id" {
  description = "The deployment ID from the Act onboarding values. It names the StackSet `ActSecurity-Connector-<deployment_id>`, which is how Act finds it."
  type        = string
}

variable "role_name" {
  description = "Name of the role in this account, `role_name` from the Act onboarding values."
  type        = string
}

variable "member_role_name" {
  description = "Name of the role in each member account, `member_role_name` from the Act onboarding values. Null uses `role_name`."
  type        = string
  default     = null
}

variable "member_role_path" {
  description = "IAM path of the member roles, `member_role_path` from the Act onboarding values."
  type        = string
  default     = "/"
  nullable    = false
}

variable "external_id" {
  description = "The external ID every Act role's trust policy requires, `external_id` from the Act onboarding values. Not a secret."
  type        = string
}

variable "act_principal_arn" {
  description = "The Act principal the roles trust, `act_principal_arn` from the Act onboarding values."
  type        = string
}

variable "deprecated_principal_arns" {
  description = "Act principals being retired that the roles keep trusting during a rotation, `deprecated_principal_arns` from the Act onboarding values."
  type        = list(string)
  default     = []
  nullable    = false
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
  description = "Member accounts the StackSet skips, as 12-digit IDs. Pass the same list to `excluded_account_ids` of `act_aws_organization_deployment`."
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
  description = "ARN of a permissions boundary to attach to the role in this account. Member roles get none."
  type        = string
  default     = null
}

variable "tags" {
  description = "AWS tags for the role, policies and StackSet."
  type        = map(string)
  default     = {}
  nullable    = false
}
