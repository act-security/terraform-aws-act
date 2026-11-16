output "deployment_id" {
  description = "The Act deployment ID."
  value       = module.act.deployment_id
}

output "console_url" {
  description = "The deployment's page in the Act console."
  value       = module.act.console_url
}
