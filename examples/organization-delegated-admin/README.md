# Organization from a StackSets delegated administrator

Run this root in a CloudFormation StackSets delegated administrator account, such as a security tooling account. The module creates the Act role in this account and a service-managed StackSet, called as `DELEGATED_ADMIN`, that creates the member roles. The StackSet skips this account because the module creates its role directly.

A delegated administrator cannot list the organization roots, so set `root_id` or `organizational_unit_ids`.

## Prerequisites, once, in the management account

Turn on trusted access for StackSets with AWS Organizations:

```sh
aws cloudformation activate-organizations-access
```

Register this account as a StackSets delegated administrator, from a separate root that runs in the management account:

```hcl
resource "aws_organizations_delegated_administrator" "stacksets" {
  account_id        = "111111111111"
  service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
}
```
