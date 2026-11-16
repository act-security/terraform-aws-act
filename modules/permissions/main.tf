locals {
  permissions_template = "${path.module}/permissions.yaml.tftpl"

  permissions = yamldecode(templatefile(local.permissions_template, {
    partition              = var.partition
    account_id             = var.account_id
    role_name              = var.role_name
    cloudtrail_bucket_name = var.cloudtrail_bucket_name
  }))

  enabled_capabilities = var.enable_eks_cluster_access ? ["eks_cluster_access"] : []

  custom_policies = merge(
    local.permissions.policies,
    [for capability in local.enabled_capabilities : local.permissions.capabilities[capability]]...
  )

  managed_policy_arns = [
    for policy in local.permissions.managed_policies : "arn:${var.partition}:iam::aws:policy/${policy}"
  ]
}
