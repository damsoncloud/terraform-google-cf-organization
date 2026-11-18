output "firebase_projects" {
  description = "IDs and numbers of the Firebase projects."
  value       = module.organization.firebase_projects
}

output "perimeter_name" {
  description = "Resource name of the perimeter, for the modules adding their projects."
  value       = module.vpc_service_controls.perimeter_name
}
