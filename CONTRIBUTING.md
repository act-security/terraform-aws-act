# Contributing

## Setup

```sh
mise trust && mise install
make check
```

`mise.toml` pins every tool and `mise.lock` pins their checksums for Linux, macOS and Windows. CI installs from the same files, so a green `make check` locally means a green CI run. After changing a tool version, run `mise lock --platform linux-x64,linux-arm64,macos-arm64,macos-x64,windows-x64`.

## Checks

| Command | What it runs |
|---|---|
| `make fmt-check` | `terraform fmt -recursive -check` |
| `make lint` | tflint with every rule of the Terraform ruleset, on every module and example |
| `make docs-check` | fails when a README differs from what terraform-docs generates; `make docs` regenerates them |
| `make validate` | `terraform validate` on every module and example |
| `make test` | `terraform test` with mock providers, no cloud or Act account needed |
| `make workflow-lint` | actionlint and zizmor |

CI runs `validate` on Terraform 1.5.7 and the pinned version, and `test` on Terraform 1.7.5 and the pinned version, because mock providers need 1.7.

Until the Act provider release that ships the deployment resources is on the registry, `make validate` and `make test` build the provider from source at `ACT_PROVIDER_REF` into a local filesystem mirror under `.act-provider/`. Remove the `act-provider` target once that release is published.

## Applying against a real account

Set `ACT_CLIENT_ID` and `ACT_CLIENT_SECRET` to a write key of a test tenant, point the `aws` provider at a sandbox account, and apply one of the `examples/`. Destroy afterwards: an account deployment has deletion protection off, an organization deployment has it on, so set `deletion_protection = false` and apply before you destroy it.

## Permissions

`modules/permissions/permissions.yaml.tftpl` is the only place permissions live. Both the role in the current account and the member-account StackSet render from it. Granting more is a breaking change: title the pull request `feat!:` so release-please cuts a major once the module is at 1.0. Removing a permission is a minor.

The `deployment_version` in that file is the value Act compares with the role's `DeploymentVersion` tag. Update it together with the policy content, to the version Act ships with that content.

## Rules

- No comments in Terraform, YAML or the Makefile. Put the reasoning in variable descriptions, the README headers (`.header.md`) or the pull request.
- No `provider` blocks in a module. Examples may configure providers.
- Pull request titles are conventional commits. Pull requests are squash-merged, and release-please builds versions and the changelog from the titles.
- Never commit a real client secret, token, tenant ID or account ID. Use the documentation placeholders already in the examples.

## Pull requests from forks

CI does not run on pull requests from forks. A maintainer reviews the diff, pushes the commits to a branch in this repository and opens a new pull request from it. The contributor keeps authorship of the commits.

## Releases

Maintainers merge the release pull request release-please opens. Merging it tags `vX.Y.Z`, and the Terraform Registry publishes the tag.

See also [SECURITY.md](SECURITY.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
