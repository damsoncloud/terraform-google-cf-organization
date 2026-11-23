locals {
  shared_vpc_project_ids = var.shared_vpc == null ? {} : {
    for name, host in var.shared_vpc.host_projects : name => coalesce(host.project_id, "${local.common_short_name}-shared-vpcs-${name}-${random_id.suffix.hex}")
  }
  apps_script_project_id = var.apps_script == null ? null : coalesce(var.apps_script.project_id, "${local.common_short_name}-apps-script-${random_id.suffix.hex}")

  firebase_environments = var.firebase == null ? [] : coalesce(var.firebase.environments, [for environment in keys(local.environments) : environment if !var.folders[environment].common])
  firebase_projects = { for environment in local.firebase_environments : environment => {
    project_id = lookup(var.firebase.project_ids, environment, "${local.environments[environment]}-firebase-${random_id.suffix.hex}")
    folder_id  = var.folders[environment].id
  } }

  # Granted on the developers' folders, in addition to their other roles
  firebase_developer_roles = ["roles/firebase.developAdmin", "roles/firebase.growthAdmin", "roles/firebase.qualityAdmin"]
}

# The optional Shared VPC host projects, which cf-shared-vpc configures; a host project and its service projects must be in the same perimeter
resource "google_project" "shared_vpc" {
  for_each = local.shared_vpc_project_ids

  name                = each.value
  project_id          = each.value
  folder_id           = local.common_folder_id
  billing_account     = var.billing_account
  auto_create_network = false

  lifecycle {
    precondition {
      condition     = length(each.value) <= 30
      error_message = "The generated project ID ${each.value} is longer than 30 characters: shorten the common environment's short name or the host project's name, or set its project_id."
    }
  }
}

module "apps_script" {
  source = "./modules/apps-script"
  count  = var.apps_script != null ? 1 : 0

  project_id      = local.apps_script_project_id
  folder_id       = local.common_folder_id
  billing_account = var.billing_account
  apis            = var.apps_script.apis
}

module "firebase" {
  source = "./modules/firebase"
  count  = var.firebase != null ? 1 : 0

  projects        = local.firebase_projects
  billing_account = var.billing_account
  apis            = var.firebase.apis
}

module "defender_for_cloud" {
  source = "./modules/defender-for-cloud"
  count  = var.defender_for_cloud ? 1 : 0

  organization_id = var.organization_id
  project_id      = google_project.observability.project_id
}
