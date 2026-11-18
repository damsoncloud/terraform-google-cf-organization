# The Standard Cloud Project of every Apps Script, instead of a hidden project created for each script
resource "google_project" "this" {
  name                = var.project_id
  project_id          = var.project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "this" {
  for_each = toset(var.apis)

  project            = google_project.this.project_id
  service            = each.key
  disable_on_destroy = false
}
