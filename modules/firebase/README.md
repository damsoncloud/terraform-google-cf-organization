# Firebase projects

Submodule of [cf-organization](../../README.md) creating one Firebase project per environment folder, with the Firebase APIs enabled. Firebase is added to each project in
the Firebase console, choosing the existing project. It is called by cf-organization when its `firebase` input is set.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| apis | Firebase APIs enabled in the projects. | `list(string)` | n/a | yes |
| billing\_account | ID of the billing account of the projects. | `string` | n/a | yes |
| projects | The Firebase projects by environment folder name: `project_id` and the folder (`folder_id`, `folders/<id>`). | ```map(object({ project_id = string folder_id = string }))``` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| projects | IDs and numbers of the projects, by environment folder name. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
