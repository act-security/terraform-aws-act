locals {
  policies_dir = "${path.module}/../../policies"
  manifest     = jsondecode(file("${local.policies_dir}/manifest.json"))

  permission_groups_given = var.permission_groups != null
  legacy_group_enabled = {
    kubernetes      = coalesce(var.enable_eks_cluster_access, true)
    cloudtrail_logs = true
    ai_services     = true
  }
  group_enabled = {
    for entry in local.manifest.permission_groups : entry.group => (
      local.permission_groups_given ? try(var.permission_groups[entry.group], null) != null : local.legacy_group_enabled[entry.group]
    )
  }
  cloudtrail_bucket_name = local.permission_groups_given ? coalesce(try(var.permission_groups.cloudtrail_logs.bucket, null), "*") : coalesce(var.cloudtrail_bucket_name, "*")

  template_values = {
    partition              = var.partition
    account_id             = var.account_id
    role_name              = var.role_name
    cloudtrail_bucket_name = local.cloudtrail_bucket_name
  }

  core_policy_documents = {
    for policy in local.manifest.core_policies : policy.name => jsonencode(jsondecode(templatefile("${local.policies_dir}/${policy.file}", local.template_values)))
  }

  group_policy_documents = {
    for entry in local.manifest.permission_groups : entry.policy.name => jsonencode(jsondecode(templatefile("${local.policies_dir}/${entry.policy.file}", local.template_values)))
    if local.group_enabled[entry.group]
  }

  policy_files = concat(
    ["manifest.json"],
    [for policy in local.manifest.core_policies : policy.file],
    [for entry in local.manifest.permission_groups : entry.policy.file],
  )
  permissions_hash = sha256(join("", [for name in local.policy_files : filesha256("${local.policies_dir}/${name}")]))
}
