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

  folder_id            = module.hierarchy.folders["common"]
  billing_account      = "012345-6789AB-CDEF01"
  billing_admins_group = "gcp-billing-admins@example.com"
  bootstrap_project_id = module.bootstrap.project_id
}
```

Pin an exact version. New versions are published as immutable GitHub releases with `vX.Y.Z` tags, following [semantic versioning](https://semver.org/).

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| api\_management\_project\_id | ID of the API Management Hub project. Generated as `cmn-api-management-hub-<suffix>`, with the suffix of a generated Observability project ID, when null; set it to keep the ID of an existing project. | `string` | `null` | no |
| billing\_account | ID of the billing account of the foundations' projects and their budgets, e.g. `012345-6789AB-CDEF01`. | `string` | n/a | yes |
| billing\_admins\_group | Email of the group administering the billing account, e.g. `gcp-billing-admins@example.com`, notified of the budgets' alerts. | `string` | n/a | yes |
| bootstrap\_project\_id | ID of the bootstrap project, e.g. the `project_id` output of cf-bootstrap, which gets a budget. | `string` | n/a | yes |
| budget\_amounts | Budget amounts of the foundations' projects, in the billing account's currency, alerting at 50%, 70% and 100%. | ```object({ bootstrap = optional(number, 100) observability = optional(number, 100) api_management = optional(number, 100) })``` | `{}` | no |
| folder\_id | The `common` folder holding the foundations' projects, as `folders/<id>`, e.g. the `folders["common"]` output of cf-hierarchy. | `string` | n/a | yes |
| observability\_project\_id | ID of the Observability project. Generated as `cmn-observability-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| api\_management\_project\_id | ID of the API Management Hub project. |
| billing\_disabler\_email | Email of the billing disabler service account, running the billing disabler deployed by cf-observability. |
| billing\_notification\_channel | ID of the notification channel of the billing administrators group (`projects/<project>/notificationChannels/<id>`). |
| observability\_project\_id | ID of the Observability project. |
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
