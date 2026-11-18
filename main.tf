locals {
  observability_project_id  = coalesce(var.observability_project_id, "cmn-observability-${random_id.suffix.hex}")
  api_management_project_id = coalesce(var.api_management_project_id, "cmn-api-management-hub-${random_id.suffix.hex}")
}

# Makes the globally unique generated project IDs unique
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "observability" {
  name                = local.observability_project_id
  project_id          = local.observability_project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "observability" {
  for_each = toset([
    # keep-sorted start
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    # keep-sorted end
  ])

  project            = google_project.observability.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_project" "api_management" {
  name                = local.api_management_project_id
  project_id          = local.api_management_project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}
