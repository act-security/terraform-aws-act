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
| `make docs-check` | fails when `docs/permissions.md` differs from `policies/` or a README differs from what terraform-docs generates; `make docs` regenerates them |
| `make validate` | `terraform validate` on every module and example |
| `make test` | `terraform test` with a mock `aws` provider, no AWS account needed |
| `make workflow-lint` | actionlint and zizmor |

CI runs `validate` on Terraform 1.5.7 and the pinned version, and `test` on Terraform 1.7.5 and the pinned version, because mock providers need 1.7. `scripts/render-permissions.ts` runs on Node from `mise.toml`; `make lint` also typechecks it.

## Applying against a real account

Point the `aws` provider at a sandbox account, or a sandbox organization's management account, apply one of the `examples/` with the onboarding values of a test tenant, register the outputs with Act to check that Act accepts the role, then destroy.

## Permissions

`policies/` is the only place permissions live: `manifest.json` lists the AWS managed policies and the Act policy files, and each Act policy is a JSON policy document. The role in the current account, the member-account StackSet and the Permissions section of the README are all built from these files. The content mirrors what Act requests from the console; change it only together with Act's onboarding. Granting more is a breaking change: title the pull request `feat!:` so release-please cuts a major once the module is at 1.0.

`deployment_version` in `manifest.json` is the value Act compares with the role's `DeploymentVersion` tag. Update it together with the policy content, to the version Act ships with that content.

## Rules

- No comments in Terraform, TypeScript, YAML or the Makefile. Put the reasoning in variable descriptions, the README headers (`.header.md`) or the pull request.
- The module uses only the `aws` provider and has no `provider` blocks. Examples may configure providers.
- Pull request titles are conventional commits. Pull requests are squash-merged, and release-please builds versions and the changelog from the titles.
- Never commit a real client secret, token, tenant ID or account ID. Use the documentation placeholders already in the examples.

## Pull requests from forks

CI does not run on pull requests from forks. A maintainer reviews the diff, pushes the commits to a branch in this repository and opens a new pull request from it. The contributor keeps authorship of the commits.

## Releases

Maintainers merge the release pull request release-please opens. Merging it tags `vX.Y.Z`, and the Terraform Registry publishes the tag.

See also [SECURITY.md](SECURITY.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
