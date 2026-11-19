output "projects" {
  description = "IDs and numbers of the projects, by environment folder name."
  value = { for environment, project in google_project.firebase : environment => {
    project_id = project.project_id
    number     = project.number
  } }
}
