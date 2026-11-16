# Account role

Creates only the IAM role Act assumes, with the permissions of this module release, and no Act resource. Use it where the role and the Act deployment are created by different pipelines, and pass the values from the `act_aws_onboarding_parameters` data source.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| aws | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | >= 5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| permissions | ../permissions | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.act](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_principal\_arn | The Act principal the role trusts, `act_principal_arn` of the `act_aws_onboarding_parameters` data source. | `string` | n/a | yes |
| external\_id | The external ID the trust policy requires, `external_id` of the `act_aws_onboarding_parameters` data source. Not a secret. | `string` | n/a | yes |
| role\_name | Name of the IAM role, `role_name` of the `act_aws_onboarding_parameters` data source. | `string` | n/a | yes |
| cloudtrail\_bucket\_name | The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket. | `string` | `"*"` | no |
| deprecated\_principal\_arns | Act principals being retired that the role keeps trusting during a rotation, `deprecated_principal_arns` of the `act_aws_onboarding_parameters` data source. | `list(string)` | `[]` | no |
| enable\_eks\_cluster\_access | Let Act create a view-only EKS access entry for this role so it can scan Kubernetes inside EKS clusters. | `bool` | `false` | no |
| permissions\_boundary\_arn | ARN of a permissions boundary to attach to the role. | `string` | `null` | no |
| tags | AWS tags for the role and its policies. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| assume\_role\_policy | The role's trust policy as JSON. |
| deployment\_version | The Act role version this module release deploys, stamped on the role as the `DeploymentVersion` tag. |
| permissions\_hash | SHA-256 of the permissions this module release grants. |
| policy\_arns | Every policy attached to the role, AWS managed and Act custom. |
| role\_arn | ARN of the role Act assumes. |
| role\_name | Name of the role Act assumes. |