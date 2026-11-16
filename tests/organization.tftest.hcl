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

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_organizations_organization" {
    defaults = {
      id    = "o-abcdefghij"
      roots = [{ id = "r-ab12", arn = "", name = "Root", policy_types = [] }]
    }
  }
}

mock_provider "act" {
  mock_data "act_current_identity" {
    defaults = {
      tenant_id = "8d3c1f0a-2b4e-4c6d-9e8f-0a1b2c3d4e5f"
    }
  }

  mock_data "act_aws_onboarding_parameters" {
    defaults = {
      deployment_id             = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      role_name                 = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      member_role_name          = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      member_role_path          = "/"
      act_principal_arn         = "arn:aws:iam::222222222222:role/act-principal"
      deprecated_principal_arns = []
      external_id               = "act-external-id"
      external_id_key_version   = 1
      deployment_version        = "20261109-4aa4885f"
      existing_deployment = {
        id          = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
        status      = "active"
        created_via = "api"
      }
    }
  }
}

run "covers_the_root_from_the_management_account" {
  command = plan

  module {
    source = "./modules/organization"
  }

  assert {
    condition     = act_aws_organization_deployment.this.organization_id == "o-abcdefghij"
    error_message = "The deployment must target the organization the aws provider runs in."
  }

  assert {
    condition     = act_aws_organization_deployment.this.root_id == "r-ab12"
    error_message = "With no targets the module covers the root."
  }

  assert {
    condition     = act_aws_organization_deployment.this.deletion_protection
    error_message = "An organization deployment is protected by default."
  }

  assert {
    condition     = aws_cloudformation_stack_set.members.name == "ActSecurity-Connector-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "Act finds the StackSet by this name."
  }

  assert {
    condition     = aws_cloudformation_stack_set.members.call_as == "SELF"
    error_message = "The management account calls the StackSet as itself."
  }

  assert {
    condition     = aws_cloudformation_stack_instances.members.deployment_targets[0].account_filter_type == "NONE"
    error_message = "Nothing is filtered when no account is excluded."
  }

  assert {
    condition     = aws_cloudformation_stack_instances.members.deployment_targets[0].organizational_unit_ids == toset(["r-ab12"])
    error_message = "The StackSet must target the root."
  }
}

run "renders_member_policies_per_account" {
  command = plan

  module {
    source = "./modules/organization"
  }

  assert {
    condition = toset(keys(jsondecode(aws_cloudformation_stack_set.members.template_body).Resources)) == toset([
      "ActSecurityRole",
      "ActSecurityCustomPolicy1",
      "ActSecurityCustomPolicy2",
      "ActSecurityEksClusterAccess",
    ])
    error_message = "The member template must create the role and one managed policy per Act policy."
  }

  assert {
    condition     = strcontains(jsondecode(aws_cloudformation_stack_set.members.template_body).Resources.ActSecurityEksClusterAccess.Properties.PolicyDocument["Fn::Sub"], "arn:aws:iam::$${AWS::AccountId}:role/ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d")
    error_message = "Member policies must resolve the account in each member account."
  }

  assert {
    condition     = jsondecode(aws_cloudformation_stack_set.members.template_body).Resources.ActSecurityRole.Properties.RoleName == "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "Member roles must take the name Act issued."
  }

  assert {
    condition     = length(aws_cloudformation_stack_set.members.template_body) <= 51200
    error_message = "The member template must fit the CloudFormation template body limit."
  }
}

run "skips_the_delegated_admin_account" {
  command = plan

  module {
    source = "./modules/organization"
  }

  variables {
    call_as                 = "DELEGATED_ADMIN"
    organizational_unit_ids = ["ou-ab12-11111111", "ou-ab12-22222222"]
    excluded_account_ids    = ["333333333333"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.members.call_as == "DELEGATED_ADMIN"
    error_message = "A delegated administrator calls the StackSet as one."
  }

  assert {
    condition     = aws_cloudformation_stack_instances.members.deployment_targets[0].account_filter_type == "DIFFERENCE"
    error_message = "Excluded accounts must be filtered out of the StackSet."
  }

  assert {
    condition     = aws_cloudformation_stack_instances.members.deployment_targets[0].accounts == toset(["111111111111", "333333333333"])
    error_message = "The StackSet must skip excluded accounts and the delegated administrator, whose role this module creates directly."
  }

  assert {
    condition     = act_aws_organization_deployment.this.excluded_account_ids == toset(["333333333333"])
    error_message = "Act keeps scanning the delegated administrator account."
  }

  assert {
    condition     = act_aws_organization_deployment.this.root_id == null
    error_message = "Organizational units replace the root."
  }
}

run "refuses_root_and_units_together" {
  command = plan

  module {
    source = "./modules/organization"
  }

  variables {
    root_id                 = "r-ab12"
    organizational_unit_ids = ["ou-ab12-11111111"]
  }

  expect_failures = [data.act_aws_onboarding_parameters.this]
}

run "needs_targets_where_roots_are_hidden" {
  command = plan

  module {
    source = "./modules/organization"
  }

  override_data {
    target = data.aws_organizations_organization.this
    values = {
      id    = "o-abcdefghij"
      roots = []
    }
  }

  variables {
    call_as = "DELEGATED_ADMIN"
  }

  expect_failures = [data.act_aws_onboarding_parameters.this]
}
