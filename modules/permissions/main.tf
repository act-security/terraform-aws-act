locals {
  policies_dir = "${path.module}/../../policies"
  manifest     = jsondecode(file("${local.policies_dir}/manifest.json"))

  enabled_capabilities = {
    enable_eks_cluster_access = var.enable_eks_cluster_access
  }

  attached_custom_policies = [
    for policy in local.manifest.custom_policies : policy
    if policy.capability == null || try(local.enabled_capabilities[policy.capability], false)
  ]

  custom_policy_documents = {
    for policy in local.attached_custom_policies : policy.name => jsonencode(jsondecode(templatefile("${local.policies_dir}/${policy.file}", {
      partition              = var.partition
      account_id             = var.account_id
      role_name              = var.role_name
      cloudtrail_bucket_name = var.cloudtrail_bucket_name
    })))
  }

  permissions_hash = sha256(join("", [
    for name in concat(["manifest.json"], [for policy in local.manifest.custom_policies : policy.file]) : filesha256("${local.policies_dir}/${name}")
  ]))
}
