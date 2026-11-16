output "role_arn" {
  description = "ARN of the role Act assumes. Pass it to `role_arn` of `act_aws_account_deployment`."
  value       = aws_iam_role.act.arn
}

output "role_name" {
  description = "Name of the role Act assumes."
  value       = aws_iam_role.act.name
}

output "account_id" {
  description = "The AWS account the role is in. Pass it to `account_id` of `act_aws_account_deployment`."
  value       = data.aws_caller_identity.current.account_id
}

output "external_id" {
  description = "The external ID the role's trust policy requires, passed through. Not a secret."
  value       = var.external_id
}

output "trust_policy" {
  description = "The role's trust policy as JSON."
  value       = local.trust_policy
}

output "managed_policy_arns" {
  description = "AWS managed policies attached to the role."
  value       = module.permissions.managed_policy_arns
}

output "custom_policy_documents" {
  description = "Act policy documents attached to the role, as JSON, by name: the core policies and those of the granted permission groups."
  value       = merge(module.permissions.core_policy_documents, module.permissions.group_policy_documents)
}

output "permission_groups" {
  description = "Every permission group, true when it is granted."
  value       = module.permissions.enabled_permission_groups
}

output "disabled_capabilities" {
  description = "The Act capabilities of the permission groups left out. Pass it to `disabled_capabilities` of `act_aws_account_deployment`."
  value       = module.permissions.disabled_capabilities
}

output "deployment_version" {
  description = "The Act role version this release deploys, stamped on the role as the `DeploymentVersion` tag."
  value       = module.permissions.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 over the permission files of this release."
  value       = module.permissions.permissions_hash
}
