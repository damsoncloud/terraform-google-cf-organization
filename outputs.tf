output "observability_project_id" {
  description = "ID of the Observability project."
  value       = google_project.observability.project_id
}

output "api_management_project_id" {
  description = "ID of the API Management Hub project."
  value       = google_project.api_management.project_id
}

output "billing_notification_channel" {
  description = "ID of the notification channel of the billing administrators group (`projects/<project>/notificationChannels/<id>`)."
  value       = google_monitoring_notification_channel.billing.id
}

output "billing_disabler_email" {
  description = "Email of the billing disabler service account, running the billing disabler deployed by cf-observability."
  value       = google_service_account.billing_disabler.email
}

output "billing_disabler_project_roles" {
  description = "Roles of the billing disabler service account on each project with the billing disabler enabled, granted by cf-gcp-project."
  value       = local.billing_disabler_project_roles
}

output "model_armor" {
  description = <<-EOT
  Filters of the organisation's Model Armour floor setting, the `model_armor` input with its defaults except `enforcement`,
  for the project-level Agent Platform and Google MCP server floor settings of cf-gcp-project,
  which replace the organisation's filters and screen only with their own enforcement enabled.
  EOT
  value       = { for setting, value in var.model_armor : setting => value if setting != "enforcement" }
}

output "observability_project_number" {
  description = "Number of the Observability project, e.g. for the membership of the vpc-service-controls submodule's perimeter."
  value       = google_project.observability.number
}

output "api_management_project_number" {
  description = "Number of the API Management Hub project, e.g. for the membership of the vpc-service-controls submodule's perimeter."
  value       = google_project.api_management.number
}

output "shared_vpc_projects" {
  description = "IDs and numbers of the Shared VPC host projects, by name, for cf-shared-vpc and the perimeter's membership of the host project of its environments; empty when not created."
  value       = { for name, project in google_project.shared_vpc : name => { project_id = project.project_id, number = project.number } }
}

output "apps_script_project" {
  description = "ID and number of the Apps Script project, the Standard Cloud Project of every Apps Script; null when not created."
  value       = var.apps_script == null ? null : module.apps_script[0].project
}

output "firebase_projects" {
  description = "IDs and numbers of the Firebase projects, by environment folder name, e.g. for the org-policies submodule's `firebase` input and the perimeter's membership of the production one."
  value       = var.firebase == null ? {} : module.firebase[0].projects
}

output "firebase_apis" {
  description = "Firebase APIs enabled in the Firebase projects, for the org-policies submodule's `firebase` input; empty when Firebase is not set up."
  value       = var.firebase == null ? [] : var.firebase.apis
}

output "perimeter_groups" {
  description = "Emails of the groups whose members access the VPC Service Controls perimeter's projects from outside it, for the vpc-service-controls submodule's `groups` input."
  value = sort(distinct(concat(
    [for group in var.perimeter_groups.organization : "${group}@${var.domain}"],
    flatten([for short_name in concat([local.common_short_name], [for folder in var.perimeter_groups.environments : var.folders[folder].short_name]) : [
      for suffix in var.perimeter_groups.suffixes : "gcp-${short_name}-${suffix}@${var.domain}"
    ]]),
  )))
}

output "defender_for_cloud" {
  description = <<-EOT
  The Microsoft Defender for Cloud integration's organisation-level part, for the `azure_integration` input of cf-observability; null when not created:
    `service_accounts`, their emails by name;
    `log_collection_role`, the custom role consuming the audit log subscription;
    `external_members`, Microsoft's identities granted organisation roles, for the org-policies submodule's `additional_allowed_members`.
  EOT
  value = var.defender_for_cloud ? {
    service_accounts    = module.defender_for_cloud[0].service_accounts
    log_collection_role = module.defender_for_cloud[0].log_collection_role
    external_members    = module.defender_for_cloud[0].external_members
  } : null
}
