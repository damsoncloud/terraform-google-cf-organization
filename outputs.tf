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
