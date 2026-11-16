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
