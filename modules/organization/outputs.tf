output "deployment_id" {
  description = "The Act deployment ID."
  value       = act_aws_organization_deployment.this.id
}

output "status" {
  description = "`active` when Act can use the role, `failed` when it cannot."
  value       = act_aws_organization_deployment.this.status
}

output "console_url" {
  description = "The deployment's page in the Act console."
  value       = act_aws_organization_deployment.this.console_url
}

output "management_account_id" {
  description = "The organization's management account, as AWS reports it."
  value       = act_aws_organization_deployment.this.management_account_id
}

output "role_arn" {
  description = "ARN of the role Act assumes in this account."
  value       = module.role.role_arn
}

output "external_id" {
  description = "The external ID every Act role's trust policy requires. Not a secret."
  value       = act_aws_organization_deployment.this.external_id
}

output "stack_set_name" {
  description = "The StackSet that creates the Act role in each member account."
  value       = aws_cloudformation_stack_set.members.name
}

output "member_role_name" {
  description = "Name of the Act role in each member account."
  value       = data.act_aws_onboarding_parameters.this.member_role_name
}

output "deployment_version" {
  description = "The Act role version this module release deploys."
  value       = module.role.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 of the permissions this module release grants."
  value       = module.role.permissions_hash
}

output "update_available" {
  description = "True when Act recommends a newer role version than the one deployed."
  value       = act_aws_organization_deployment.this.update_available
}
