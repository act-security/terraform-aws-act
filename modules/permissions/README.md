# Permissions

Renders the permissions in [`policies/`](../../policies) for one role in one account. It creates nothing. The root module and `organization` use it, so the role in the current account and the member roles in the StackSet always grant the same permissions.

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
| cloudtrail\_bucket\_name | The bucket the cloudtrail\_logs group reads while `permission_groups` is null. | `string` | `"*"` | no |
| enable\_eks\_cluster\_access | Grant the kubernetes group while `permission_groups` is null. | `bool` | `true` | no |
| permission\_groups | The permission groups to grant, validated by the root module. Null grants every group, with kubernetes following `enable_eks_cluster_access` and the bucket following `cloudtrail_bucket_name`. | `any` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| core\_policy\_documents | Act policy documents every role gets, as JSON, by name. |
| deployment\_version | The Act role version these permissions belong to, stamped on the role as the `DeploymentVersion` tag. |
| disabled\_capabilities | The Act capabilities of the permission groups left out. |
| enabled\_permission\_groups | Every permission group, true when it is granted. |
| group\_policy\_documents | Act policy documents of the granted permission groups, as JSON, by name. |
| managed\_policy\_arns | AWS managed policies to attach to the role. |
| permissions\_hash | SHA-256 over every file in `policies/`. |