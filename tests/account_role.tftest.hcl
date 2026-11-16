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

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  role_name         = "ActSecurityRole-test"
  act_principal_arn = "arn:aws:iam::222222222222:role/act-principal"
  external_id       = "act-external-id"
}

run "creates_the_role_with_todays_permissions" {
  command = plan

  module {
    source = "./modules/account-role"
  }

  assert {
    condition     = aws_iam_role.act.name == "ActSecurityRole-test"
    error_message = "The role must take the given name."
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
    condition     = toset(keys(aws_iam_policy.custom)) == toset(["CustomPolicy1", "CustomPolicy2"])
    error_message = "EKS cluster access must be off by default."
  }

  assert {
    condition     = aws_iam_policy.custom["CustomPolicy1"].name == "ActSecurityRole-test-CustomPolicy1"
    error_message = "Custom policies are named after the role."
  }

  assert {
    condition     = alltrue([for policy in aws_iam_policy.custom : length(policy.policy) <= 6144])
    error_message = "Every custom policy must fit the IAM managed policy size limit."
  }
}

run "adds_eks_cluster_access" {
  command = plan

  module {
    source = "./modules/account-role"
  }

  variables {
    enable_eks_cluster_access = true
  }

  assert {
    condition     = contains(keys(aws_iam_policy.custom), "EksClusterAccess")
    error_message = "EKS cluster access adds its policy."
  }

  assert {
    condition     = strcontains(aws_iam_policy.custom["EksClusterAccess"].policy, "arn:aws:iam::111111111111:role/ActSecurityRole-test")
    error_message = "The EKS policy must name this role in this account."
  }
}

run "scopes_log_reads_to_the_cloudtrail_bucket" {
  command = plan

  module {
    source = "./modules/account-role"
  }

  variables {
    cloudtrail_bucket_name = "org-trail-logs"
  }

  assert {
    condition     = strcontains(aws_iam_policy.custom["CustomPolicy1"].policy, "arn:aws:s3:::org-trail-logs/AWSLogs/*")
    error_message = "Log reads must be limited to the CloudTrail bucket."
  }
}

run "renders_the_partition" {
  command = plan

  module {
    source = "./modules/account-role"
  }

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws-us-gov"
    }
  }

  assert {
    condition     = alltrue([for policy in aws_iam_policy.custom : !strcontains(policy.policy, "arn:aws:")])
    error_message = "Every ARN must use the partition the role lives in."
  }
}
