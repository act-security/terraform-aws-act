output "role_arn" {
  description = "ARN of the role Act assumes."
  value       = aws_iam_role.act.arn
}

output "role_name" {
  description = "Name of the role Act assumes."
  value       = aws_iam_role.act.name
}

output "deployment_version" {
  description = "The Act role version this module release deploys, stamped on the role as the `DeploymentVersion` tag."
  value       = module.permissions.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 of the permissions this module release grants."
  value       = module.permissions.permissions_hash
}

output "policy_arns" {
  description = "Every policy attached to the role, AWS managed and Act custom."
  value       = concat(module.permissions.managed_policy_arns, [for policy in aws_iam_policy.custom : policy.arn])
}

output "assume_role_policy" {
  description = "The role's trust policy as JSON."
  value       = data.aws_iam_policy_document.trust.json
}
