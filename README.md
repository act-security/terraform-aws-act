# Act module for AWS

Connects an AWS account or organization to [Act](https://act.security) in one apply. The module reads the onboarding values Act issues for the target, creates the read-only IAM role Act assumes with them, and registers the deployment through the [Act provider](https://registry.terraform.io/providers/act-security/act/latest). Nothing is copied from the Act console.

| Path | Use it for |
|---|---|
| `act-security/act/aws` | One AWS account: the account the `aws` provider runs in |
| `act-security/act/aws//modules/organization` | An AWS organization, from the management account or a CloudFormation StackSets delegated administrator |
| `act-security/act/aws//modules/account-role` | Only the IAM role, for pipelines that create roles separately from the Act deployment |

## Usage

```hcl
provider "act" {}

provider "aws" {
  region = "us-east-1"
}

module "act" {
  source  = "act-security/act/aws"
  version = "~> 0.1"

  name = "payments-prod"
}
```

Set `ACT_CLIENT_ID` and `ACT_CLIENT_SECRET` to an Act API key with write access, then run `terraform apply`. Act verifies the role before it stores the deployment, so a broken role fails the apply and leaves nothing behind.

For an organization, run the `organization` submodule in the management account. It creates the Act role there, a service-managed StackSet that creates the role in every member account, and the organization deployment:

```hcl
module "act" {
  source  = "act-security/act/aws//modules/organization"
  version = "~> 0.1"

  name                 = "acme-org"
  excluded_account_ids = ["222222222222"]
}
```

From a StackSets delegated administrator, set `call_as = "DELEGATED_ADMIN"` and the root or organizational units to cover. See [`examples/`](examples) for complete configurations.

## Permissions

Every permission the role gets ships inside the module release: `SecurityAudit`, `ViewOnlyAccess`, and Act's own read policies in [`modules/permissions/permissions.yaml.tftpl`](modules/permissions/permissions.yaml.tftpl). The Act API supplies only the role name, the Act principal and the external ID, so a module version always grants the same permissions. EKS cluster access is on, as in the Act console onboarding; set `enable_eks_cluster_access = false` to leave it out.

The role carries a `DeploymentVersion` tag. When Act recommends a newer role version, the `act_module_current` check warns at plan and the `update_available` output turns true. Upgrade the module to grant the permissions Act expects.

## Compatibility

Terraform 1.5.7 or later, the Act provider 0.3.0 or later, and the AWS provider 5.0 or later (6.0 or later for the `organization` submodule). The tests in `tests/` use mock providers and need Terraform 1.7 or later.

## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.7 |
| act | >= 0.3.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| act | >= 0.3.0 |
| aws | >= 5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| role | ./modules/account-role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [act_aws_account_deployment.this](https://registry.terraform.io/providers/act-security/act/latest/docs/resources/aws_account_deployment) | resource |
| [act_aws_onboarding_parameters.this](https://registry.terraform.io/providers/act-security/act/latest/docs/data-sources/aws_onboarding_parameters) | data source |
| [act_current_identity.current](https://registry.terraform.io/providers/act-security/act/latest/docs/data-sources/current_identity) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| act\_tags | Act tags for the deployment, at most 50. They are not AWS tags. | `map(string)` | `null` | no |
| allowed\_regions | The AWS regions Act scans, such as `us-east-1`. Null scans every region. | `set(string)` | `null` | no |
| cloudtrail\_bucket\_name | The S3 bucket CloudTrail writes to. Limits Act's log reads to that bucket. `*` reads `AWSLogs/` in any bucket. | `string` | `"*"` | no |
| deletion\_protection | When true, Act refuses to delete the deployment and a plan that destroys it fails. | `bool` | `false` | no |
| enable\_eks\_cluster\_access | Let Act create a view-only EKS access entry for its role so it can scan Kubernetes inside EKS clusters. | `bool` | `true` | no |
| expected\_tenant\_id | The Act tenant this configuration must run as. The plan fails when the act provider is authenticated to another tenant. | `string` | `null` | no |
| name | The name Act shows for the deployment, 1 to 64 characters. Act picks one when it is null. | `string` | `null` | no |
| permissions\_boundary\_arn | ARN of a permissions boundary to attach to the Act role. | `string` | `null` | no |
| tags | AWS tags for the IAM role and policies. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| console\_url | The deployment's page in the Act console. |
| deployment\_id | The Act deployment ID. |
| deployment\_version | The Act role version this module release deploys. |
| external\_id | The external ID the role's trust policy requires. Not a secret. |
| permissions\_hash | SHA-256 of the permissions this module release grants. |
| role\_arn | ARN of the role Act assumes. |
| role\_name | Name of the role Act assumes. |
| status | `active` when Act can use the role, `failed` when it cannot. |
| update\_available | True when Act recommends a newer role version than the one deployed. |