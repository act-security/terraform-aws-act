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

run "connects_the_current_account" {
  command = plan

  variables {
    name = "payments-prod"
  }

  assert {
    condition     = act_aws_account_deployment.this.account_id == "111111111111"
    error_message = "The deployment must target the account the aws provider runs in."
  }

  assert {
    condition     = act_aws_account_deployment.this.deployment_id == "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "The deployment must use the deployment ID Act issued."
  }

  assert {
    condition     = act_aws_account_deployment.this.external_id_key_version == 1
    error_message = "The deployment must pin the external ID key version."
  }

  assert {
    condition     = length(act_aws_account_deployment.this.disabled_capabilities) == 0
    error_message = "EKS cluster access must be on by default, as in Act's onboarding."
  }

  assert {
    condition     = act_aws_account_deployment.this.deletion_protection == false
    error_message = "An account deployment is not protected by default."
  }

  assert {
    condition     = output.role_name == "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
    error_message = "The role must take the name Act issued."
  }
}

run "turns_off_eks_cluster_access" {
  command = plan

  variables {
    enable_eks_cluster_access = false
  }

  assert {
    condition     = act_aws_account_deployment.this.disabled_capabilities == toset(["eks_cluster_access"])
    error_message = "Act must know EKS cluster access is off."
  }
}

run "refuses_another_tenant" {
  command = plan

  variables {
    expected_tenant_id = "00000000-0000-4000-8000-000000000000"
  }

  expect_failures = [data.act_aws_onboarding_parameters.this]
}

run "accepts_the_expected_tenant" {
  command = plan

  variables {
    expected_tenant_id = "8d3c1f0a-2b4e-4c6d-9e8f-0a1b2c3d4e5f"
  }
}

run "warns_about_a_console_deployment" {
  command = plan

  override_data {
    target = data.act_aws_onboarding_parameters.this
    values = {
      deployment_id             = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      role_name                 = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      act_principal_arn         = "arn:aws:iam::222222222222:role/act-principal"
      deprecated_principal_arns = []
      external_id               = "act-external-id"
      external_id_key_version   = 1
      deployment_version        = "20261109-4aa4885f"
      existing_deployment = {
        id          = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
        status      = "active"
        created_via = "ui"
      }
    }
  }

  expect_failures = [check.act_existing_deployment]
}

run "warns_when_act_recommends_a_newer_role" {
  command = plan

  override_data {
    target = data.act_aws_onboarding_parameters.this
    values = {
      deployment_id             = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      role_name                 = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
      act_principal_arn         = "arn:aws:iam::222222222222:role/act-principal"
      deprecated_principal_arns = []
      external_id               = "act-external-id"
      external_id_key_version   = 1
      deployment_version        = "20991231-ffffffff"
      existing_deployment = {
        id          = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
        status      = "active"
        created_via = "api"
      }
    }
  }

  expect_failures = [check.act_module_current]
}
