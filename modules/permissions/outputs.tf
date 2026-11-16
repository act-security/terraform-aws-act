output "deployment_version" {
  description = "The Act role version these permissions belong to, stamped on the role as the `DeploymentVersion` tag."
  value       = local.permissions.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 of the permission set."
  value       = filesha256(local.permissions_template)
}

output "managed_policy_arns" {
  description = "AWS managed policies to attach to the role."
  value       = local.managed_policy_arns
}

output "custom_policies" {
  description = "Act policy documents to create and attach to the role, by name suffix."
  value       = local.custom_policies
}
