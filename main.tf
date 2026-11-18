locals {
  # The environment folders, with a short name, and the common environment's folder
  environments              = { for name, folder in var.folders : name => folder.short_name if folder.short_name != null }
  common_folder             = one([for folder in values(var.folders) : folder if folder.common])
  common_folder_id          = local.common_folder.id
  common_short_name         = local.common_folder.short_name
  observability_project_id  = coalesce(var.observability_project_id, "${local.common_short_name}-observability-${random_id.suffix.hex}")
  api_management_project_id = coalesce(var.api_management_project_id, "${local.common_short_name}-api-management-hub-${random_id.suffix.hex}")
}

# Makes the globally unique generated project IDs unique
resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "observability" {
  name                = local.observability_project_id
  project_id          = local.observability_project_id
  folder_id           = local.common_folder_id
  billing_account     = var.billing_account
  auto_create_network = false

  lifecycle {
    precondition {
      condition     = length(local.observability_project_id) <= 30
      error_message = "The generated project ID ${local.observability_project_id} is longer than 30 characters: shorten the common environment's short name or set observability_project_id."
    }
  }
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
  folder_id           = local.common_folder_id
  billing_account     = var.billing_account
  auto_create_network = false

  lifecycle {
    precondition {
      condition     = length(local.api_management_project_id) <= 30
      error_message = "The generated project ID ${local.api_management_project_id} is longer than 30 characters: shorten the common environment's short name or set api_management_project_id."
    }
  }
}
