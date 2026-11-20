# Microsoft Defender for Cloud

Submodule of [cf-organization](../../README.md) creating the organisation-level part of the Microsoft Defender for Cloud integration: its service accounts, named as
Microsoft's onboarding expects, its organisation custom roles, and their organisation roles, returned for the authoritative organisation IAM policy, together with those of
Microsoft's agentless scanning identities. It is called by cf-organization when its `defender_for_cloud` input is true.

The Workload Identity Federation from Azure and the project-level resources are set up by the `azure-integration` submodule of cf-observability, which takes the `defender_for_cloud`
output of cf-organization. Microsoft's identities are outside the organisation, so they must be allowed in the `iam.managed.allowedPolicyMembers` constraint, through the
`additional_allowed_members` input of the org-policies submodule.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| organization\_id | ID of the organisation, where the custom roles are created. | `string` | n/a | yes |
| project\_id | ID of the project of the service accounts, e.g. the Observability project, where cf-observability sets up their Workload Identity Federation from Azure. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| external\_members | Microsoft's identities outside the organisation, to allow in the `iam.managed.allowedPolicyMembers` constraint. |
| log\_collection\_role | ID of the custom role consuming the audit log subscription, granted on it by cf-observability. |
| organization\_bindings | The organisation roles of the service accounts and of Microsoft's agentless scanning identities, for the authoritative organisation IAM policy. |
| service\_accounts | Emails of the service accounts by name. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
