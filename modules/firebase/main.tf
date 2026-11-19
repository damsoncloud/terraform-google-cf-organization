locals {
  services = { for pair in setproduct(keys(var.projects), var.apis) : "${pair[0]}/${pair[1]}" => { environment = pair[0], service = pair[1] } }
}

# Firebase is added to the projects in the Firebase console, choosing the existing project
resource "google_project" "firebase" {
  for_each = var.projects

  name                = each.value.project_id
  project_id          = each.value.project_id
  folder_id           = each.value.folder_id
  billing_account     = var.billing_account
  auto_create_network = false

  labels = {
    firebase      = "enabled"
    firebase-core = "enabled"
  }
}

resource "google_project_service" "firebase" {
  for_each = local.services

  project            = google_project.firebase[each.value.environment].project_id
  service            = each.value.service
  disable_on_destroy = false
}
