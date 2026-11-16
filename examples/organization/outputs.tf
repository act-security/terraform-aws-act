output "deployment_id" {
  description = "The Act deployment ID."
  value       = module.act.deployment_id
}

output "stack_set_name" {
  description = "The StackSet that creates the Act role in each member account."
  value       = module.act.stack_set_name
}
