# Organization

Connects an AWS organization to Act. Run it in the management account, or in a CloudFormation StackSets delegated administrator account with `call_as = "DELEGATED_ADMIN"`.

It creates the Act role in the current account, a service-managed StackSet named `ActSecurity-Connector-<deployment_id>` that creates the role in every member account under the targeted root or organizational units, and the `act_aws_organization_deployment`. Excluded accounts are left out of both the StackSet and Act. A delegated administrator account is left out of the StackSet only, because the module creates its role directly. Act reads member accounts from the StackSet and does not wait for the rollout.

Trusted access for StackSets with AWS Organizations must be on (`aws cloudformation activate-organizations-access`), and a delegated administrator must be registered from the management account first.

Deletion protection is on by default. Set `deletion_protection = false` and apply before you destroy.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| act | >= 0.3.0 |
| aws | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| act | >= 0.3.0 |
| aws | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| member\_permissions | ../permissions | n/a |
| role | ../account-role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [act_aws_organization_deployment.this](https://registry.terraform.io/providers/act-security/act/latest/docs/resources/aws_organization_deployment) | resource |
| [aws_cloudformation_stack_instances.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_instances) | resource |
| [aws_cloudformation_stack_set.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [act_aws_onboarding_parameters.this](https://registry.terraform.io/providers/act-security/act/latest/docs/data-sources/aws_onboarding_parameters) | data source |
| [act_current_identity.current](https://registry.terraform.io/providers/act-security/act/latest/docs/data-sources/current_identity) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_tags | Act tags for the deployment, at most 50. They are not AWS tags. | `map(string)` | `null` | no |
| allowed\_regions | The AWS regions Act scans, such as `us-east-1`. Null scans every region. | `set(string)` | `null` | no |
| call\_as | `SELF` in the management account, `DELEGATED_ADMIN` in a CloudFormation StackSets delegated administrator account. | `string` | `"SELF"` | no |
| cloudtrail\_bucket\_name | The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket. | `string` | `"*"` | no |
| deletion\_protection | When true, Act refuses to delete the deployment and a plan that destroys it fails. | `bool` | `true` | no |
| enable\_eks\_cluster\_access | Let Act create a view-only EKS access entry for its roles so it can scan Kubernetes inside EKS clusters. | `bool` | `true` | no |
| excluded\_account\_ids | Member accounts Act leaves out and the StackSet skips, as 12-digit IDs. | `set(string)` | `[]` | no |
| expected\_tenant\_id | The Act tenant this configuration must run as. The plan fails when the act provider is authenticated to another tenant. | `string` | `null` | no |
| name | The name Act shows for the deployment, 1 to 64 characters. Act picks one when it is null. | `string` | `null` | no |
| organizational\_unit\_ids | The organizational units to cover, `ou-...`. Set this or `root_id`. To leave a unit out, list the others. | `set(string)` | `[]` | no |
| permissions\_boundary\_arn | ARN of a permissions boundary to attach to the Act role in this account. Member roles get none. | `string` | `null` | no |
| root\_id | The organization root, `r-...`, to cover every account. Set this or `organizational_unit_ids`. From the management account both can be left out and the module covers the root. | `string` | `null` | no |
| tags | AWS tags for the IAM role, policies and StackSet. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| console\_url | The deployment's page in the Act console. |
| deployment\_id | The Act deployment ID. |
| deployment\_version | The Act role version this module release deploys. |
| external\_id | The external ID every Act role's trust policy requires. Not a secret. |
| management\_account\_id | The organization's management account, as AWS reports it. |
| member\_role\_name | Name of the Act role in each member account. |
| permissions\_hash | SHA-256 of the permissions this module release grants. |
| role\_arn | ARN of the role Act assumes in this account. |
| stack\_set\_name | The StackSet that creates the Act role in each member account. |
| status | `active` when Act can use the role, `failed` when it cannot. |
| update\_available | True when Act recommends a newer role version than the one deployed. |