# Permissions

Renders the permissions Act needs from `permissions.yaml.tftpl` for one role in one account. It creates nothing; `account-role` and `organization` use it so the role in the current account and the member roles in the StackSet always grant the same permissions.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | The AWS account the policies are for. | `string` | n/a | yes |
| partition | The AWS partition the policies are for, such as `aws`. | `string` | n/a | yes |
| role\_name | Name of the role the policies are attached to. | `string` | n/a | yes |
| cloudtrail\_bucket\_name | The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket. | `string` | `"*"` | no |
| enable\_eks\_cluster\_access | Include the permissions Act needs to create a view-only EKS access entry for the role. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| custom\_policies | Act policy documents to create and attach to the role, by name suffix. |
| deployment\_version | The Act role version these permissions belong to, stamped on the role as the `DeploymentVersion` tag. |
| managed\_policy\_arns | AWS managed policies to attach to the role. |
| permissions\_hash | SHA-256 of the permission set. |