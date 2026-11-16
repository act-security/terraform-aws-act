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
    condition     = aws_iam_role.act.tags["DeploymentVersion"] == "20261109-4aa4885f"
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
    condition     = toset(keys(aws_iam_policy.custom)) == toset(["CustomPolicy1", "CustomPolicy2", "EksClusterAccess"])
    error_message = "EKS cluster access must be on by default, as in Act's onboarding."
  }

  assert {
    condition     = aws_iam_policy.custom["CustomPolicy1"].name == "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d-CustomPolicy1"
    error_message = "Custom policies are named after the role."
  }

  assert {
    condition     = alltrue([for policy in aws_iam_policy.custom : length(policy.policy) <= 6144])
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
    condition     = output.custom_policy_documents["CustomPolicy1"] == aws_iam_policy.custom["CustomPolicy1"].policy
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

run "drops_eks_cluster_access" {
  command = plan

  variables {
    enable_eks_cluster_access = false
  }

  assert {
    condition     = toset(keys(aws_iam_policy.custom)) == toset(["CustomPolicy1", "CustomPolicy2"])
    error_message = "Turning EKS cluster access off drops its policy."
  }
}

run "names_this_role_in_the_eks_policy" {
  command = plan

  assert {
    condition     = strcontains(aws_iam_policy.custom["EksClusterAccess"].policy, "arn:aws:iam::111111111111:role/ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d")
    error_message = "The EKS policy must name this role in this account."
  }
}

run "scopes_log_reads_to_the_cloudtrail_bucket" {
  command = plan

  variables {
    cloudtrail_bucket_name = "org-trail-logs"
  }

  assert {
    condition     = strcontains(aws_iam_policy.custom["CustomPolicy1"].policy, "arn:aws:s3:::org-trail-logs/AWSLogs/*")
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
    condition     = strcontains(aws_iam_policy.custom["CustomPolicy1"].policy, "arn:aws-us-gov:s3:::*/AWSLogs/*")
    error_message = "The CloudTrail log ARNs must use the partition the role lives in."
  }
}
