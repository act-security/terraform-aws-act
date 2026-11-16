# Security policy

## Reporting a vulnerability

Report vulnerabilities privately, never in public issues, discussions or pull requests:

- GitHub private vulnerability reporting: https://github.com/act-security/terraform-aws-act/security/advisories/new (preferred)
- Email: security@act.security

Include the module version, the Terraform and provider versions, a configuration with every secret removed, and the impact you see.

## What to expect

- Acknowledgement within 3 business days.
- Triage within 10 business days.
- Coordinated disclosure: 90 days, or the fixed release if that comes first. We credit reporters unless they ask us not to.

## Supported versions

Before 1.0, only the latest release gets fixes. From 1.0, the latest minor of the current major.

## Scope

In scope: this module, the IAM trust and permissions it creates, and its GitHub workflows. A release whose role trusts a principal other than the one the `act_aws_onboarding_parameters` data source returns, or whose trust policy does not require the external ID, is a vulnerability.

Out of scope: the Act platform itself (report it to security@act.security directly) and the Act provider (report it in its own repository).

## What the module grants

Every permission ships inside the release, in `modules/permissions/permissions.yaml.tftpl`. The Act API supplies only the role name, the Act principal and the external ID, never policy content. Compare `permissions_hash` across versions to see whether an upgrade changes what Act can read.
