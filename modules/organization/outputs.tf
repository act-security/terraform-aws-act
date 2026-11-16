output "role_arn" {
  description = "ARN of the role Act assumes in this account. Pass it to `role_arn` of `act_aws_organization_deployment`."
  value       = module.role.role_arn
}

output "role_name" {
  description = "Name of the role Act assumes in this account."
  value       = module.role.role_name
}

output "external_id" {
  description = "The external ID every Act role's trust policy requires, passed through. Not a secret."
  value       = var.external_id
}

output "organization_id" {
  description = "The AWS organization, `o-...`. Pass it to `organization_id` of `act_aws_organization_deployment`."
  value       = data.aws_organizations_organization.this.id
}

output "root_id" {
  description = "The root the StackSet targets, or null when it targets organizational units. Pass it to `root_id` of `act_aws_organization_deployment`."
  value       = local.root_id
}

output "organizational_unit_ids" {
  description = "The organizational units the StackSet targets, or null when it targets the root. Pass it to `organizational_unit_ids` of `act_aws_organization_deployment`."
  value       = local.root_id == null ? var.organizational_unit_ids : null
}

output "excluded_account_ids" {
  description = "Member accounts left out, passed through. Pass it to `excluded_account_ids` of `act_aws_organization_deployment`."
  value       = var.excluded_account_ids
}

output "stack_set_id" {
  description = "ID of the StackSet that creates the Act role in each member account."
  value       = aws_cloudformation_stack_set.members.stack_set_id
}

output "stack_set_name" {
  description = "Name of the StackSet that creates the Act role in each member account."
  value       = aws_cloudformation_stack_set.members.name
}

output "member_role_name" {
  description = "Name of the Act role in each member account."
  value       = local.member_role_name
}

output "managed_policy_arns" {
  description = "AWS managed policies attached to every Act role."
  value       = module.role.managed_policy_arns
}

output "custom_policy_documents" {
  description = "Act policy documents attached to the role in this account, as JSON, by name. Member roles get the same documents for their own account."
  value       = module.role.custom_policy_documents
}

output "permission_groups" {
  description = "Every permission group, true when it is granted."
  value       = module.role.permission_groups
}

output "disabled_capabilities" {
  description = "The Act capabilities of the permission groups left out. Pass it to `disabled_capabilities` of `act_aws_organization_deployment`."
  value       = module.role.disabled_capabilities
}

output "deployment_version" {
  description = "The Act role version this release deploys."
  value       = module.role.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 over the permission files of this release."
  value       = module.role.permissions_hash
}
