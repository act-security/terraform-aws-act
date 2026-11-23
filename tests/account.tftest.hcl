mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

variables {
  role_name         = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  external_id       = "act-external-id"
  act_principal_arn = "arn:aws:iam::222222222222:role/act-principal"
}

run "creates_the_role_with_todays_permissions" {
  command = plan

  assert {
    condition     = aws_iam_role.act.name == "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "The role must take the name Act issued."
  }

  assert {
    condition     = aws_iam_role.act.tags["DeploymentVersion"] == "20261123-4ad80fa5"
    error_message = "The role must carry the DeploymentVersion tag Act reads."
  }

  assert {
    condition = toset(keys(aws_iam_role_policy_attachment.managed)) == toset([
      "arn:aws:iam::aws:policy/SecurityAudit",
      "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    ])
    error_message = "The role must attach SecurityAudit and ViewOnlyAccess."
  }

  assert {
    condition     = toset(keys(aws_iam_policy.core)) == toset(["CustomPolicy1", "CustomPolicy2"])
    error_message = "Every role gets the two core policies."
  }

  assert {
    condition     = toset(keys(aws_iam_policy.group)) == toset(["EksClusterAccess", "CloudTrailLogs", "AiServices"])
    error_message = "Every permission group is granted by default, as in the Act console."
  }

  assert {
    condition     = length(output.disabled_capabilities) == 0
    error_message = "No capability is disabled by default."
  }

  assert {
    condition     = aws_iam_policy.core["CustomPolicy1"].name == "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d-CustomPolicy1"
    error_message = "Custom policies are named after the role."
  }

  assert {
    condition     = alltrue([for policy in merge(aws_iam_policy.core, aws_iam_policy.group) : length(policy.policy) <= 6144])
    error_message = "Every custom policy must fit the IAM managed policy size limit."
  }

  assert {
    condition     = output.account_id == "111111111111"
    error_message = "The account ID is the account the aws provider runs in."
  }

  assert {
    condition     = output.external_id == "act-external-id"
    error_message = "The external ID is passed through."
  }

  assert {
    condition     = output.custom_policy_documents["CustomPolicy1"] == aws_iam_policy.core["CustomPolicy1"].policy && output.custom_policy_documents["AiServices"] == aws_iam_policy.group["AiServices"].policy
    error_message = "The custom policy output must be what the role gets."
  }
}

run "trusts_only_act_with_the_external_id" {
  command = plan

  variables {
    deprecated_principal_arns = ["arn:aws:iam::222222222222:role/act-principal-old"]
  }

  assert {
    condition = jsondecode(aws_iam_role.act.assume_role_policy).Statement[0].Principal.AWS == [
      "arn:aws:iam::222222222222:role/act-principal",
      "arn:aws:iam::222222222222:role/act-principal-old",
    ]
    error_message = "The role must trust the Act principal and the ones being retired."
  }

  assert {
    condition     = jsondecode(aws_iam_role.act.assume_role_policy).Statement[0].Condition.StringEquals["sts:ExternalId"] == "act-external-id"
    error_message = "The role must require the external ID."
  }

  assert {
    condition     = length(jsondecode(aws_iam_role.act.assume_role_policy).Statement) == 1
    error_message = "The trust policy must hold only the Act statement."
  }
}

run "legacy_eks_variable_turns_kubernetes_off" {
  command = plan

  variables {
    enable_eks_cluster_access = false
  }

  assert {
    condition     = toset(keys(aws_iam_policy.group)) == toset(["CloudTrailLogs", "AiServices"])
    error_message = "enable_eks_cluster_access = false must drop only the kubernetes policy."
  }

  assert {
    condition     = output.disabled_capabilities == tolist(["eks_cluster_access"])
    error_message = "Act must be told EKS cluster access is off."
  }
}

run "empty_permission_groups_grants_no_group" {
  command = plan

  variables {
    permission_groups = {}
  }

  assert {
    condition     = length(aws_iam_policy.group) == 0 && length(aws_iam_role_policy_attachment.group) == 0
    error_message = "permission_groups = {} must grant no group policy."
  }

  assert {
    condition     = toset(keys(aws_iam_policy.core)) == toset(["CustomPolicy1", "CustomPolicy2"])
    error_message = "The core policies stay without any group."
  }

  assert {
    condition     = output.disabled_capabilities == tolist(["ai_services", "cloudtrail_logs", "eks_cluster_access"])
    error_message = "Act must be told every capability is off."
  }
}

run "cloudtrail_logs_off" {
  command = plan

  variables {
    permission_groups = { kubernetes = {}, ai_services = {} }
  }

  assert {
    condition     = toset(keys(aws_iam_policy.group)) == toset(["EksClusterAccess", "AiServices"])
    error_message = "Leaving cloudtrail_logs out must drop only its policy."
  }

  assert {
    condition     = output.disabled_capabilities == tolist(["cloudtrail_logs"])
    error_message = "Act must be told CloudTrail logs are off."
  }
}

run "ai_services_off" {
  command = plan

  variables {
    permission_groups = { kubernetes = {}, cloudtrail_logs = {} }
  }

  assert {
    condition     = toset(keys(aws_iam_policy.group)) == toset(["EksClusterAccess", "CloudTrailLogs"])
    error_message = "Leaving ai_services out must drop only its policy."
  }

  assert {
    condition     = output.disabled_capabilities == tolist(["ai_services"])
    error_message = "Act must be told AI services are off."
  }
}

run "kubernetes_off" {
  command = plan

  variables {
    permission_groups = { cloudtrail_logs = {}, ai_services = {} }
  }

  assert {
    condition     = toset(keys(aws_iam_policy.group)) == toset(["CloudTrailLogs", "AiServices"])
    error_message = "Leaving kubernetes out must drop only its policy."
  }
}

run "permission_groups_bucket_scopes_cloudtrail_logs" {
  command = plan

  variables {
    cloudtrail_bucket_name = "ignored-bucket"
    permission_groups      = { cloudtrail_logs = { bucket = "group-trail-bucket" }, ai_services = {}, kubernetes = {} }
  }

  assert {
    condition     = strcontains(aws_iam_policy.group["CloudTrailLogs"].policy, "arn:aws:s3:::group-trail-bucket/AWSLogs/*")
    error_message = "permission_groups.cloudtrail_logs.bucket must scope the CloudTrail log reads and win over cloudtrail_bucket_name."
  }
}

run "unknown_group_fails" {
  command = plan

  variables {
    permission_groups = { kubernetes = {}, ai_service = {} }
  }

  expect_failures = [var.permission_groups]
}

run "unknown_group_setting_fails" {
  command = plan

  variables {
    permission_groups = { ai_services = { bucket = "trail-bucket" } }
  }

  expect_failures = [var.permission_groups]
}

run "invalid_bucket_fails" {
  command = plan

  variables {
    permission_groups = { cloudtrail_logs = { bucket = "Not_A_Bucket" } }
  }

  expect_failures = [var.permission_groups]
}

run "group_reads_live_only_in_their_policies" {
  command = plan

  assert {
    condition     = alltrue([for policy in aws_iam_policy.core : !strcontains(policy.policy, "AWSLogs") && !strcontains(policy.policy, "bedrock")])
    error_message = "CloudTrail log and AI service reads live only in their groups."
  }
}

run "names_this_role_in_the_eks_policy" {
  command = plan

  assert {
    condition     = strcontains(aws_iam_policy.group["EksClusterAccess"].policy, "arn:aws:iam::111111111111:role/ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d")
    error_message = "The EKS policy must name this role in this account."
  }
}

run "scopes_log_reads_to_the_cloudtrail_bucket" {
  command = plan

  variables {
    cloudtrail_bucket_name = "org-trail-logs"
  }

  assert {
    condition     = strcontains(aws_iam_policy.group["CloudTrailLogs"].policy, "arn:aws:s3:::org-trail-logs/AWSLogs/*")
    error_message = "Log reads must be limited to the CloudTrail bucket."
  }
}

run "renders_the_partition_where_act_does" {
  command = plan

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws-us-gov"
    }
  }

  assert {
    condition     = strcontains(aws_iam_policy.group["CloudTrailLogs"].policy, "arn:aws-us-gov:s3:::*/AWSLogs/*")
    error_message = "The CloudTrail log ARNs must use the partition the role lives in."
  }
}
