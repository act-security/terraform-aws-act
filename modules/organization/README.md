# Organization

Creates the Act role in the current account and a service-managed StackSet named `ActSecurity-Connector-<deployment_id>` that creates the same role in every member account under the targeted root or organizational units. Act finds the StackSet by that name and reads the member accounts from it.

Run it in the management account, or in a CloudFormation StackSets delegated administrator account with `call_as = "DELEGATED_ADMIN"`. A delegated administrator cannot list the organization roots, so set `root_id` or `organizational_unit_ids` there. The StackSet skips the delegated administrator account, because the module creates its role directly. `excluded_account_ids` leaves accounts out of the StackSet; pass the same list to Act.

Trusted access for StackSets with AWS Organizations must be on (`aws cloudformation activate-organizations-access`), and a delegated administrator must be registered from the management account first.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| aws | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| member\_permissions | ../permissions | n/a |
| role | ../.. | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudformation_stack_instances.units](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_instances) | resource |
| [aws_cloudformation_stack_set.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_principal\_arn | The Act principal the roles trust, `act_principal_arn` from the Act onboarding values. | `string` | n/a | yes |
| deployment\_id | The deployment ID from the Act onboarding values. It names the StackSet `ActSecurity-Connector-<deployment_id>`, which is how Act finds it. | `string` | n/a | yes |
| external\_id | The external ID every Act role's trust policy requires, `external_id` from the Act onboarding values. Not a secret. | `string` | n/a | yes |
| role\_name | Name of the role in this account, `role_name` from the Act onboarding values. | `string` | n/a | yes |
| call\_as | `SELF` in the management account, `DELEGATED_ADMIN` in a CloudFormation StackSets delegated administrator account. | `string` | `"SELF"` | no |
| cloudtrail\_bucket\_name | The S3 bucket your CloudTrail trail writes logs to. `*` lets Act read logs under `AWSLogs/` in any bucket. Ignored when `permission_groups` is set. | `string` | `"*"` | no |
| deprecated\_principal\_arns | Act principals being retired that the roles keep trusting during a rotation, `deprecated_principal_arns` from the Act onboarding values. | `list(string)` | `[]` | no |
| enable\_eks\_cluster\_access | See access inside your EKS clusters. If turned off, Act sees your EKS clusters but not the access inside them. Ignored when `permission_groups` is set. | `bool` | `true` | no |
| excluded\_account\_ids | Member accounts the StackSet skips, as 12-digit IDs. Pass the same list to `excluded_account_ids` of `act_aws_organization_deployment`. | `set(string)` | `[]` | no |
| member\_role\_name | Name of the role in each member account, `member_role_name` from the Act onboarding values. Null uses `role_name`. | `string` | `null` | no |
| member\_role\_path | IAM path of the member roles, `member_role_path` from the Act onboarding values. | `string` | `"/"` | no |
| organizational\_unit\_ids | The organizational units to cover, `ou-...`. Set this or `root_id`. To leave a unit out, list the others. | `set(string)` | `[]` | no |
| permission\_groups | The permission groups to grant every Act role, each set to {}: `kubernetes`, `cloudtrail_logs` (optionally `{ bucket = "<name>" }` to limit log reads to that bucket) and `ai_services`. A group left out is not granted, and `{}` grants none. When set, it decides every group and the bucket, and `enable_eks_cluster_access` and `cloudtrail_bucket_name` are ignored. Null grants every group, as the Act console does by default. | `any` | `null` | no |
| permissions\_boundary\_arn | ARN of a permissions boundary to attach to the role in this account. Member roles get none. | `string` | `null` | no |
| root\_id | The organization root, `r-...`, to cover every account. Set this or `organizational_unit_ids`. From the management account both can be left out and the module covers the root. | `string` | `null` | no |
| tags | AWS tags for the role, policies and StackSet. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| custom\_policy\_documents | Act policy documents attached to the role in this account, as JSON, by name. Member roles get the same documents for their own account. |
| deployment\_version | The Act role version this release deploys. |
| disabled\_capabilities | The Act capabilities of the permission groups left out. Pass it to `disabled_capabilities` of `act_aws_organization_deployment`. |
| excluded\_account\_ids | Member accounts left out, passed through. Pass it to `excluded_account_ids` of `act_aws_organization_deployment`. |
| external\_id | The external ID every Act role's trust policy requires, passed through. Not a secret. |
| managed\_policy\_arns | AWS managed policies attached to every Act role. |
| member\_role\_name | Name of the Act role in each member account. |
| organization\_id | The AWS organization, `o-...`. Pass it to `organization_id` of `act_aws_organization_deployment`. |
| organizational\_unit\_ids | The organizational units the StackSet targets, or null when it targets the root. Pass it to `organizational_unit_ids` of `act_aws_organization_deployment`. |
| permission\_groups | Every permission group, true when it is granted. |
| permissions\_hash | SHA-256 over the permission files of this release. |
| role\_arn | ARN of the role Act assumes in this account. Pass it to `role_arn` of `act_aws_organization_deployment`. |
| role\_name | Name of the role Act assumes in this account. |
| root\_id | The root the StackSet targets, or null when it targets organizational units. Pass it to `root_id` of `act_aws_organization_deployment`. |
| stack\_set\_id | ID of the StackSet that creates the Act role in each member account. |
| stack\_set\_name | Name of the StackSet that creates the Act role in each member account. |