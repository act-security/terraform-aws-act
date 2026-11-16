locals {
  member_role_resource = "ActSecurityRole"

  member_policy_resources = {
    for name, document in module.member_permissions.custom_policy_documents : "ActSecurity${name}" => {
      Type = "AWS::IAM::ManagedPolicy"
      Properties = {
        ManagedPolicyName = "${local.member_role_name}-${name}"
        Description       = "Act read permissions: ${name}"
        PolicyDocument    = { "Fn::Sub" = document }
      }
    }
  }

  member_role_properties = {
    RoleName                 = local.member_role_name
    Path                     = var.member_role_path
    Description              = "Read-only role Act assumes with an external ID"
    AssumeRolePolicyDocument = jsondecode(module.role.trust_policy)
    ManagedPolicyArns = concat(
      module.member_permissions.managed_policy_arns,
      [for resource in keys(local.member_policy_resources) : { Ref = resource }],
    )
    Tags = [
      for key, value in merge(var.tags, { DeploymentVersion = module.member_permissions.deployment_version }) : {
        Key   = key
        Value = value
      }
    ]
  }

  member_template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Act read-only role for an AWS organization member account"
    Resources = merge(local.member_policy_resources, {
      (local.member_role_resource) = {
        Type       = "AWS::IAM::Role"
        Properties = local.member_role_properties
      }
    })
    Outputs = {
      RoleArn = {
        Value = { "Fn::GetAtt" = [local.member_role_resource, "Arn"] }
      }
    }
  }
}
