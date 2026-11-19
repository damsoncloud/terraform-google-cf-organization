output "project" {
  description = "ID and number of the project."
  value = {
    project_id = google_project.apps_script.project_id
    number     = google_project.apps_script.number
  }
}
