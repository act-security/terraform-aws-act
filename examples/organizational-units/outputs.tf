output "role_arn" {
  description = "Pass to `role_arn` of `act_aws_organization_deployment`."
  value       = module.act.role_arn
}

output "organization_id" {
  description = "Pass to `organization_id` of `act_aws_organization_deployment`."
  value       = module.act.organization_id
}

output "organizational_unit_ids" {
  description = "Pass to `organizational_unit_ids` of `act_aws_organization_deployment`."
  value       = module.act.organizational_unit_ids
}

output "stack_set_name" {
  description = "The StackSet that creates the member roles."
  value       = module.act.stack_set_name
}
