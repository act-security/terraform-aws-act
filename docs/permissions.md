## Permissions

The role gets these permissions and nothing else: exactly what Act requests when you connect AWS from the Act console. The files in [`policies/`](policies) are the only source; the module and this section are built from them, and CI fails when this section drifts from them. Member roles in an organization get the same set. The role carries the tag `DeploymentVersion = 20261109-4aa4885f`.

### AWS managed policies

| Policy | Why |
| ------ | --- |
| [`SecurityAudit`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/SecurityAudit.html) `arn:aws:iam::aws:policy/SecurityAudit` | Reads the security configuration of every AWS service: IAM, network, encryption and logging settings. |
| [`ViewOnlyAccess`](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/ViewOnlyAccess.html) `arn:aws:iam::aws:policy/job-function/ViewOnlyAccess` | Lists and describes resources across AWS services, so Act can inventory what exists. |

### Act policies

Each file is an IAM policy document. `${account_id}`, `${partition}`, `${role_name}` and `${cloudtrail_bucket_name}` are filled in for the account the role is in.

| Policy | File | Attached | Statements | Services |
| ------ | ---- | -------- | ---------- | -------- |
| `CustomPolicy1` | [`policies/custom-policy-1.json`](policies/custom-policy-1.json) | Always | 14 | `bedrock`, `dynamodb`, `eks`, `kafka`, `kafka-cluster`, `kinesis`, `kms`, `lambda`, `logs`, `organizations`, `s3`, `s3express`, `ssm` |
| `CustomPolicy2` | [`policies/custom-policy-2.json`](policies/custom-policy-2.json) | Always | 11 | `aoss`, `apigateway`, `bedrock-agentcore`, `cloudformation`, `cloudhsm`, `cloudtrail`, `iot`, `s3`, `sagemaker`, `signin` |
| `EksClusterAccess` | [`policies/eks-cluster-access.json`](policies/eks-cluster-access.json) | When `enable_eks_cluster_access` is true (the default) | 5 | `eks` |
