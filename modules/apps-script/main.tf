# The Standard Cloud Project of every Apps Script, instead of a hidden project created for each script
resource "google_project" "apps_script" {
  name                = var.project_id
  project_id          = var.project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "apps_script" {
  for_each = toset(var.apis)

  project            = google_project.apps_script.project_id
  service            = each.key
  disable_on_destroy = false
}
