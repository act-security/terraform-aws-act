SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ACT_PROVIDER_REPO ?= https://github.com/act-security/terraform-provider-act.git
ACT_PROVIDER_REF ?= 4e88b510f2a76566d96096f7753fc35e2c012637
ACT_PROVIDER_VERSION ?= 0.3.0
ACT_PROVIDER_DIR := $(CURDIR)/.act-provider
ACT_PROVIDER_PLATFORM = $(shell go env GOOS)_$(shell go env GOARCH)
ACT_PROVIDER_MIRROR := $(ACT_PROVIDER_DIR)/mirror
ACT_PROVIDER_RC := $(ACT_PROVIDER_DIR)/terraformrc

MODULE_DIRS := . $(wildcard modules/*)
EXAMPLE_DIRS := $(wildcard examples/*)

.PHONY: check
check: fmt-check lint docs-check validate test workflow-lint

.PHONY: fmt
fmt:
	terraform fmt -recursive

.PHONY: fmt-check
fmt-check:
	terraform fmt -recursive -check -diff

.PHONY: lint
lint:
	tflint --init
	tflint --recursive --config $(CURDIR)/.tflint.hcl

.PHONY: docs
docs:
	terraform-docs .

.PHONY: docs-check
docs-check:
	terraform-docs --output-check .

.PHONY: act-provider
act-provider: $(ACT_PROVIDER_RC)

$(ACT_PROVIDER_RC):
	rm -rf $(ACT_PROVIDER_DIR)
	git clone --quiet --filter=blob:none $(ACT_PROVIDER_REPO) $(ACT_PROVIDER_DIR)/src
	git -C $(ACT_PROVIDER_DIR)/src checkout --quiet $(ACT_PROVIDER_REF)
	cd $(ACT_PROVIDER_DIR)/src && CGO_ENABLED=0 go build -trimpath \
	  -o $(ACT_PROVIDER_MIRROR)/registry.terraform.io/act-security/act/$(ACT_PROVIDER_VERSION)/$(ACT_PROVIDER_PLATFORM)/terraform-provider-act_v$(ACT_PROVIDER_VERSION) .
	printf 'provider_installation {\n  filesystem_mirror {\n    path    = "%s"\n    include = ["registry.terraform.io/act-security/act"]\n  }\n  direct {\n    exclude = ["registry.terraform.io/act-security/act"]\n  }\n}\n' '$(ACT_PROVIDER_MIRROR)' > $@

.PHONY: validate
validate: act-provider
	for dir in $(MODULE_DIRS) $(EXAMPLE_DIRS); do \
	  echo "validate $$dir"; \
	  TF_CLI_CONFIG_FILE=$(ACT_PROVIDER_RC) terraform -chdir=$$dir init -backend=false -input=false -no-color > /dev/null; \
	  TF_CLI_CONFIG_FILE=$(ACT_PROVIDER_RC) terraform -chdir=$$dir validate -no-color; \
	done

.PHONY: test
test: act-provider
	TF_CLI_CONFIG_FILE=$(ACT_PROVIDER_RC) terraform init -backend=false -input=false -no-color > /dev/null
	TF_CLI_CONFIG_FILE=$(ACT_PROVIDER_RC) terraform test -no-color

.PHONY: workflow-lint
workflow-lint:
	actionlint
	zizmor --offline --min-severity medium .github/workflows

.PHONY: clean
clean:
	rm -rf $(ACT_PROVIDER_DIR)
	find . -name .terraform -type d -prune -exec rm -rf {} +
	find . -name .terraform.lock.hcl -delete

.PHONY: help
help:
	@printf '%s\n' \
	  'check          fmt-check lint docs-check validate test workflow-lint' \
	  'fmt            terraform fmt in place' \
	  'lint           tflint on every module and example' \
	  'docs           regenerate the READMEs with terraform-docs' \
	  'docs-check     fail when a README is stale' \
	  'act-provider   build the act provider at ACT_PROVIDER_REF into a local mirror as ACT_PROVIDER_VERSION' \
	  'validate       terraform validate every module and example' \
	  'test           terraform test with mock providers (Terraform 1.7 or later)' \
	  'workflow-lint  actionlint and zizmor' \
	  'clean          remove the provider mirror and every .terraform directory'
