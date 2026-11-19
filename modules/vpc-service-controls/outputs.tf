output "access_policy_id" {
  description = "ID of the organisation's access policy."
  value       = local.access_policy_id
}

output "perimeter_name" {
  description = "Resource name of the perimeter (`accessPolicies/<id>/servicePerimeters/<name>`), for the modules adding their projects and ingress rules to its enforced and dry-run configurations."
  value       = google_access_context_manager_service_perimeter.foundations.name
}
