# Damson Cloud GCP Cloud Foundations: organisation

Terraform module of the Damson Cloud GCP Cloud Foundations configuring a Google Cloud organisation:

* the Observability and API Management Hub projects, the billing notification channel and the budgets of the foundations' projects,
* the billing disabler service account,
* authoritative organisation and folder IAM, including the organisation's Data Access audit log configuration,
* the organisation-level Model Armour floor setting.

Submodules, applied in the same Terraform state:

* `modules/org-policies` - organisation policies, with dry-run and enforced modes,
* `modules/vpc-service-controls` - the access policy and the VPC Service Controls perimeter, with dry-run and enforced modes.

> [!WARNING]
> The organisation and folder IAM policies are authoritative: every binding not declared through the inputs is removed, including the existing ones and those of
> Google-managed service agents granted at the organisation level. Add the bindings to keep to `additional_organization_bindings` and `additional_folder_bindings`.

## Usage

```hcl
module "organization" {
  source  = "damsoncloud/cf-organization/google"
  version = "X.Y.Z"

  organization_id = "123456789012"
  domain              = "example.com"
  environment_tag_key = module.hierarchy.environment_tag_key_namespaced_name
  folders             = module.hierarchy.folders
  billing_account     = "012345-6789AB-CDEF01"

  bootstrap_project_id            = module.bootstrap.project_id
  tf_bootstrap_email              = module.bootstrap.tf_bootstrap_email
  tf_bootstrap_organization_roles = module.bootstrap.tf_bootstrap_organization_roles
  tf_plan_email                   = module.bootstrap.tf_plan_email
  tf_plan_organization_roles      = module.bootstrap.tf_plan_organization_roles
  tf_environment_emails           = module.bootstrap.tf_environment_emails
}
```

Pin an exact version. New versions are published as immutable GitHub releases with `vX.Y.Z` tags, following [semantic versioning](https://semver.org/).

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_folder\_bindings | Further folder members by folder name and role. | `map(map(list(string)))` | `{}` | no |
| additional\_organization\_bindings | Further organisation members by role, e.g. `serviceAccount:` or `group:` members, and the Google-managed service agents granted at the organisation level, which the authoritative policy would remove otherwise. | `map(list(string))` | `{}` | no |
| api\_management\_project\_id | ID of the API Management Hub project. Generated as `<common short name>-api-management-hub-<suffix>`, e.g. `cmn-api-management-hub-<suffix>`, with the suffix of a generated Observability project ID, when null; set it to keep the ID of an existing project. | `string` | `null` | no |
| audit\_log\_types | Data Access audit log types enabled for all services in the organisation; none when empty. Admin Activity audit logs are always written. | `list(string)` | ```[ "ADMIN_READ", "DATA_READ", "DATA_WRITE" ]``` | no |
| billing\_account | ID of the billing account of the foundations' projects and their budgets, e.g. `012345-6789AB-CDEF01`. | `string` | n/a | yes |
| billing\_admins\_group\_name | Name of the group administering the billing account, without the domain, notified of the budgets' alerts. | `string` | `"gcp-billing-admins"` | no |
| bootstrap\_project\_id | ID of the bootstrap project, e.g. the `project_id` output of cf-bootstrap, which gets a budget. | `string` | n/a | yes |
| budget\_amounts | Budget amounts of the foundations' projects, in the billing account's currency, alerting at 50%, 70% and 100%. | ```object({ bootstrap = optional(number, 100) observability = optional(number, 100) api_management = optional(number, 100) })``` | `{}` | no |
| domain | Domain of the organisation's groups, e.g. `example.com` for `gcp-organization-admins@example.com`. | `string` | n/a | yes |
| environment\_deployer\_roles | Roles of each environment deployer service account on its environment folder. | `list(string)` | ```[ "roles/resourcemanager.projectIamAdmin", "roles/writer" ]``` | no |
| environment\_group\_roles | Roles of each environment folder's groups by group name suffix; e.g. `sres` grants the roles to `gcp-dev-sres` on the `development` folder. | `map(list(string))` | ```{ "sres": [ "roles/iam.siteReliabilityEngineer" ], "viewers": [ "roles/reader" ] }``` | no |
| environment\_tag\_key | Namespaced name of the `environment` tag key (`<organization_id>/environment`), e.g. the `environment_tag_key_namespaced_name` output of cf-hierarchy. The groups granted roles on a folder see it through the Folder Viewer role on the organisation, limited to the folder's tag value. | `string` | n/a | yes |
| folder\_group\_roles | Further roles of groups on folders, by folder name and group name without the domain. | `map(map(list(string)))` | ```{ "development": { "gcp-dev-developers": [ "roles/iam.databasesAdmin", "roles/iam.devOps", "roles/iam.infrastructureAdmin" ] } }``` | no |
| folders | The folders by folder name, e.g. the `folders` output of cf-hierarchy, each tagged with its name as the `environment` tag value: `id`, the resource name (`folders/<id>`); `short_name`, the environment's short name, null for folders other than environments; `common`, whether it is the common environment. Each folder's IAM policy is set authoritatively, and each environment folder gets the `gcp-<short name>-<suffix>` groups of `environment_group_roles`. The foundations' projects are created in the common environment's folder and their generated IDs start with its short name. | ```map(object({ id = string short_name = optional(string) common = optional(bool, false) }))``` | n/a | yes |
| legacy\_admins\_group\_name | Name of the group administering the `legacy` folder, without the domain. | `string` | `"gcp-legacy-admins"` | no |
| legacy\_admins\_roles | Roles of the legacy administrators group on the `legacy` folder, if it is one of the folders. | `list(string)` | ```[ "roles/admin" ]``` | no |
| observability\_project\_id | ID of the Observability project. Generated as `<common short name>-observability-<suffix>`, e.g. `cmn-observability-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project. | `string` | `null` | no |
| organization\_group\_roles | Organisation roles by group name, without the domain. | `map(list(string))` | ```{ "gcp-billing-admins": [ "roles/billing.admin", "roles/billing.creator" ], "gcp-organization-admins": [ "roles/billing.user", "roles/resourcemanager.organizationAdmin", "roles/resourcemanager.projectCreator" ] }``` | no |
| organization\_id | ID of the organisation, whose IAM policy is set authoritatively. | `string` | n/a | yes |
| tf\_bootstrap\_email | Email of the `tf-bootstrap` service account, e.g. the `tf_bootstrap_email` output of cf-bootstrap. | `string` | n/a | yes |
| tf\_bootstrap\_organization\_roles | Organisation roles of `tf-bootstrap`, e.g. the `tf_bootstrap_organization_roles` output of cf-bootstrap. | `list(string)` | n/a | yes |
| tf\_environment\_emails | Emails of the environment deployer service accounts by environment folder name, e.g. the `tf_environment_emails` output of cf-bootstrap. Each gets `environment_deployer_roles` on its folder. | `map(string)` | n/a | yes |
| tf\_plan\_email | Email of the `tf-plan` service account, e.g. the `tf_plan_email` output of cf-bootstrap. | `string` | n/a | yes |
| tf\_plan\_organization\_roles | Organisation roles of `tf-plan`, e.g. the `tf_plan_organization_roles` output of cf-bootstrap. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| api\_management\_project\_id | ID of the API Management Hub project. |
| billing\_disabler\_email | Email of the billing disabler service account, running the billing disabler deployed by cf-observability. |
| billing\_disabler\_project\_roles | Roles of the billing disabler service account on each project with the billing disabler enabled, granted by cf-gcp-project. |
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
