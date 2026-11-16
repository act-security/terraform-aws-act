output "deployment_version" {
  description = "The Act role version these permissions belong to, stamped on the role as the `DeploymentVersion` tag."
  value       = local.manifest.deployment_version
}

output "permissions_hash" {
  description = "SHA-256 over every file in `policies/`."
  value       = local.permissions_hash
}

output "managed_policy_arns" {
  description = "AWS managed policies to attach to the role."
  value       = [for policy in local.manifest.managed_policies : policy.arn]
}

output "custom_policy_documents" {
  description = "Act policy documents to create and attach to the role, as JSON, by name."
  value       = local.custom_policy_documents
}
