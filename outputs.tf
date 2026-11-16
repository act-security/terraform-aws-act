output "deployment_id" {
  description = "The Act deployment ID."
  value       = act_aws_account_deployment.this.id
}

output "status" {
  description = "`active` when Act can use the role, `failed` when it cannot."
  value       = act_aws_account_deployment.this.status
}

output "console_url" {
  description = "The deployment's page in the Act console."
  value       = act_aws_account_deployment.this.console_url
}

output "role_arn" {
  description = "ARN of the role Act assumes."
  value       = module.role.role_arn
}

output "role_name" {
  description = "Name of the role Act assumes."
  value       = module.role.role_name
}

output "external_id" {
  description = "The external ID the role's trust policy requires. Not a secret."
  value       = act_aws_account_deployment.this.external_id
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
  value       = act_aws_account_deployment.this.update_available
}
