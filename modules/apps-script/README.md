# Apps Script project

Submodule of [cf-organization](../../README.md) creating the project in which every Apps Script runs, as its Standard Cloud Project, instead of a hidden project created for
each script. It is called by cf-organization when its `apps_script` input is set, which is the default.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| apis | APIs enabled in the project, used by the Apps Scripts. | `list(string)` | n/a | yes |
| billing\_account | ID of the billing account of the project. | `string` | n/a | yes |
| folder\_id | The folder of the project (`folders/<id>`), e.g. the common environment's. | `string` | n/a | yes |
| project\_id | ID of the Apps Script project. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| project | ID and number of the project. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
