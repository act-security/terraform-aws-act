output "role_arn" {
  description = "Pass to `role_arn` of `act_aws_account_deployment`."
  value       = module.act.role_arn
}

output "account_id" {
  description = "Pass to `account_id` of `act_aws_account_deployment`."
  value       = module.act.account_id
}
