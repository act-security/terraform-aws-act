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

output "core_policy_documents" {
  description = "Act policy documents every role gets, as JSON, by name."
  value       = local.core_policy_documents
}

output "group_policy_documents" {
  description = "Act policy documents of the granted permission groups, as JSON, by name."
  value       = local.group_policy_documents
}

output "enabled_permission_groups" {
  description = "Every permission group, true when it is granted."
  value       = local.group_enabled
}

output "disabled_capabilities" {
  description = "The Act capabilities of the permission groups left out."
  value       = sort([for entry in local.manifest.permission_groups : entry.capability if !local.group_enabled[entry.group]])
}
