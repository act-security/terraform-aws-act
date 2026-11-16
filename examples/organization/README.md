# Organization from the management account

Run this root in the AWS Organizations management account. The module creates the Act role in the management account, a service-managed StackSet that creates the role in every member account under the root, and the Act organization deployment.

Trusted access for StackSets with AWS Organizations must be on. Turn it on once with:

```sh
aws cloudformation activate-organizations-access
```
