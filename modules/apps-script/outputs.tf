output "project" {
  description = "ID and number of the project."
  value = {
    project_id = google_project.this.project_id
    number     = google_project.this.number
  }
}
