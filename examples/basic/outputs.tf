output "observability_project_id" {
  description = "ID of the Observability project."
  value       = module.organization.observability_project_id
}

output "api_management_project_id" {
  description = "ID of the API Management Hub project."
  value       = module.organization.api_management_project_id
}

output "apps_script_project" {
  description = "ID and number of the Apps Script project."
  value       = module.organization.apps_script_project
}
