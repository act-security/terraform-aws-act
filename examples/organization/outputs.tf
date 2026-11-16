output "role_arn" {
  description = "Pass to `role_arn` of `act_aws_organization_deployment`."
  value       = module.act.role_arn
}

output "organization_id" {
  description = "Pass to `organization_id` of `act_aws_organization_deployment`."
  value       = module.act.organization_id
}

output "root_id" {
  description = "Pass to `root_id` of `act_aws_organization_deployment`."
  value       = module.act.root_id
}

output "stack_set_name" {
  description = "The StackSet that creates the member roles."
  value       = module.act.stack_set_name
}
