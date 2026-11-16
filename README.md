# Act module for AWS

Creates the AWS resources [Act](https://act.security) needs to read an AWS account or organization: a read-only IAM role that trusts Act with an external ID, and for an organization, a service-managed StackSet that creates the same role in every member account. The module uses only the `aws` provider and creates nothing in Act.

Its inputs are the onboarding values Act issues for the target (role name, external ID, Act principal and, for an organization, the deployment ID). Its outputs are what you register with Act afterwards: the role ARN, the account or organization, the StackSet and its targets.

| Target | Module | Where you run it |
| ------ | ------ | ---------------- |
| One account | `act-security/act/aws` | The account |
| A whole organization | `act-security/act/aws//modules/organization` | The management account, or a StackSets delegated administrator with `root_id` |
| Some organizational units | `act-security/act/aws//modules/organization` with `organizational_unit_ids` | The management account or a StackSets delegated administrator |

## Usage

One account:

```hcl
module "act" {
  source  = "act-security/act/aws"
  version = "~> 0.1"

  role_name         = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  external_id       = "8c0f4b6e-2d1a-4f3c-9b7e-6a5d4c3b2a10"
  act_principal_arn = "arn:aws:iam::222222222222:role/act-principal"
}
```

A whole organization, from the management account:

```hcl
module "act" {
  source  = "act-security/act/aws//modules/organization"
  version = "~> 0.1"

  deployment_id     = "5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  role_name         = "ActSecurityRole-5a7e2c1d-3b4f-4a6e-8c9d-0e1f2a3b4c5d"
  external_id       = "8c0f4b6e-2d1a-4f3c-9b7e-6a5d4c3b2a10"
  act_principal_arn = "arn:aws:iam::222222222222:role/act-principal"
}
```

Set `organizational_unit_ids` to cover some units instead of the root, and `call_as = "DELEGATED_ADMIN"` to run from a StackSets delegated administrator. See [`examples/`](examples) for each target.

Every permission group (Kubernetes inside EKS, CloudTrail logs, AI services) is granted by default, as in the Act console. Set `permission_groups` to grant only some of them, and pass the `disabled_capabilities` output to Act.

## Compatibility

Terraform 1.5.7 or later and the AWS provider 5.0 or later, 6.0 or later for the `organization` submodule. The tests in `tests/` use a mock provider and need Terraform 1.7 or later.

## Permissions

The role gets these permissions and nothing else: exactly what Act requests when you connect AWS from the Act console. The files in [`policies/`](policies) are the only source; the module and this section are built from them, and CI fails when this section drifts from them. Member roles in an organization get the same set. The role carries the tag `DeploymentVersion = 20261116-28c5963b`.

### AWS managed policies

| Policy | Why |
| ------ | --- |
| [`SecurityAudit`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/SecurityAudit.html) `arn:aws:iam::aws:policy/SecurityAudit` | Reads the security configuration of every AWS service: IAM, network, encryption and logging settings. |
| [`ViewOnlyAccess`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/ViewOnlyAccess.html) `arn:aws:iam::aws:policy/job-function/ViewOnlyAccess` | Lists and describes resources across AWS services, so Act can inventory what exists. |

### Act core policies

Every role gets these. Each file is an IAM policy document; `${account_id}`, `${partition}`, `${role_name}` and `${cloudtrail_bucket_name}` are filled in for the account the role is in.

| Policy | File | Statements | Services |
| ------ | ---- | ---------- | -------- |
| `CustomPolicy1` | [`policies/custom-policy-1.json`](policies/custom-policy-1.json) | 8 | `dynamodb`, `eks`, `kafka`, `kafka-cluster`, `kinesis`, `lambda`, `organizations`, `s3express`, `ssm` |
| `CustomPolicy2` | [`policies/custom-policy-2.json`](policies/custom-policy-2.json) | 8 | `apigateway`, `cloudformation`, `cloudhsm`, `cloudtrail`, `iot`, `s3`, `signin` |

### Permission groups

Every group is granted by default, as in the Act console. Set `permission_groups` to the groups to grant, for example `{ kubernetes = {}, cloudtrail_logs = { bucket = "org-trail-logs" } }`; a group left out is not granted. Pass the `disabled_capabilities` output to the Act deployment so Act knows what it cannot read.

| Group | What it grants | Act capability | Policy | Statements | Services |
| ----- | -------------- | -------------- | ------ | ---------- | -------- |
| `kubernetes` | **Scan Kubernetes inside EKS clusters.** Lets the role create a view-only EKS access entry for itself on each cluster and read Kubernetes objects through it. | `eks_cluster_access` | [`policies/eks-cluster-access.json`](policies/eks-cluster-access.json) | 5 | `eks` |
| `cloudtrail_logs` | **CloudTrail logs.** Lets the role read CloudTrail log files in S3 and log events in CloudWatch Logs, and decrypt them with KMS through those services. | `cloudtrail_logs` | [`policies/cloudtrail-logs.json`](policies/cloudtrail-logs.json) | 5 | `kms`, `logs`, `s3` |
| `ai_services` | **AI services.** Lets the role read Amazon Bedrock, Bedrock AgentCore, OpenSearch Serverless and SageMaker model package group details the AWS managed policies leave out. | `ai_services` | [`policies/ai-services.json`](policies/ai-services.json) | 4 | `aoss`, `bedrock`, `bedrock-agentcore`, `sagemaker` |

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
| permissions | ./modules/permissions | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.act](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_principal\_arn | The Act principal the role trusts, `act_principal_arn` from the Act onboarding values. | `string` | n/a | yes |
| external\_id | The external ID the role's trust policy requires, `external_id` from the Act onboarding values. Not a secret. | `string` | n/a | yes |
| role\_name | Name of the IAM role, `role_name` from the Act onboarding values. | `string` | n/a | yes |
| cloudtrail\_bucket\_name | The S3 bucket your CloudTrail trail writes logs to. `*` lets Act read logs under `AWSLogs/` in any bucket. Ignored when `permission_groups` is set. | `string` | `"*"` | no |
| deprecated\_principal\_arns | Act principals being retired that the role keeps trusting during a rotation, `deprecated_principal_arns` from the Act onboarding values. | `list(string)` | `[]` | no |
| enable\_eks\_cluster\_access | See access inside your EKS clusters. If turned off, Act sees your EKS clusters but not the access inside them. Ignored when `permission_groups` is set. | `bool` | `true` | no |
| permission\_groups | The permission groups to grant, each set to {}: `kubernetes`, `cloudtrail_logs` (optionally `{ bucket = "<name>" }` to limit log reads to that bucket) and `ai_services`. A group left out is not granted, and `{}` grants none. When set, it decides every group and the bucket, and `enable_eks_cluster_access` and `cloudtrail_bucket_name` are ignored. Null grants every group, with kubernetes following `enable_eks_cluster_access` and the bucket following `cloudtrail_bucket_name`, as the Act console does by default. | `any` | `null` | no |
| permissions\_boundary\_arn | ARN of a permissions boundary to attach to the role. | `string` | `null` | no |
| tags | AWS tags for the role and its policies. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| account\_id | The AWS account the role is in. Pass it to `account_id` of `act_aws_account_deployment`. |
| custom\_policy\_documents | Act policy documents attached to the role, as JSON, by name: the core policies and those of the granted permission groups. |
| deployment\_version | The Act role version this release deploys, stamped on the role as the `DeploymentVersion` tag. |
| disabled\_capabilities | The Act capabilities of the permission groups left out. Pass it to `disabled_capabilities` of `act_aws_account_deployment`. |
| external\_id | The external ID the role's trust policy requires, passed through. Not a secret. |
| managed\_policy\_arns | AWS managed policies attached to the role. |
| permission\_groups | Every permission group, true when it is granted. |
| permissions\_hash | SHA-256 over the permission files of this release. |
| role\_arn | ARN of the role Act assumes. Pass it to `role_arn` of `act_aws_account_deployment`. |
| role\_name | Name of the role Act assumes. |
| trust\_policy | The role's trust policy as JSON. |