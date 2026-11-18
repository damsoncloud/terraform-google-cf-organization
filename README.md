# Damson Cloud GCP Cloud Foundations: organisation

Terraform module of the Damson Cloud GCP Cloud Foundations configuring a Google Cloud organisation:

* the Observability and API Management Hub projects, the billing notification channel and the budgets of the foundations' projects,
* the billing disabler service account,
* authoritative organisation and folder IAM,
* the organisation-level Model Armour floor setting.

Submodules, applied in the same Terraform state:

* `modules/org-policies` - organisation policies, with dry-run and enforced modes,
* `modules/vpc-service-controls` - the access policy and the VPC Service Controls perimeter, with dry-run and enforced modes.

## Usage

```hcl
module "organization" {
  source  = "damsoncloud/cf-organization/google"
  version = "X.Y.Z"

  # Inputs are documented once the module's first version is released.
}
```

Pin an exact version. New versions are published as immutable GitHub releases with `vX.Y.Z` tags, following [semantic versioning](https://semver.org/).

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

No inputs.

## Outputs

No outputs.
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

## Releases

Releases are dispatched manually on `main` with the [`release.yaml`](.github/workflows/release.yaml) workflow, choosing the part of the version to increase. It calls the
[`github-release.yaml`](https://github.com/damsoncloud/dcp.sdlc#reusable-workflows) reusable workflow, which creates the GitHub release and its tag. The Terraform Registry
publishes the new version from the tag.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

## Development

The repository uses [devenv](https://devenv.sh) with the shared [devenvbase](https://github.com/damsoncloud/dcp.sdlc/blob/main/devenvbase/README.md), pinned to a
[dcp.sdlc](https://github.com/damsoncloud/dcp.sdlc) release in `devenv.yaml`.

* `devenv shell` starts the shell.
* `devenv test` runs the git hooks and tests.
* `terraform_docs` regenerates the inputs and outputs above, which the `terraform-docs` git hook also does on commit.

The weekly `dcp.sdlc check` workflow opens an issue when a newer dcp.sdlc release is available. Upgrade with `devenv shell -- dcp_sdlc_upgrade_pr`, which also updates
the devenv inputs, runs the tests and opens a pull request.

## Licence

[Apache License 2.0](LICENSE)
