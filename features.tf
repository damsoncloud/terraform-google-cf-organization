locals {
  apps_script_project_id = var.apps_script == null ? null : coalesce(var.apps_script.project_id, "${local.common_short_name}-apps-script-${random_id.suffix.hex}")

  firebase_environments = var.firebase == null ? [] : coalesce(var.firebase.environments, [for environment in keys(local.environments) : environment if !var.folders[environment].common])
  firebase_projects = { for environment in local.firebase_environments : environment => {
    project_id = lookup(var.firebase.project_ids, environment, "${local.environments[environment]}-firebase-${random_id.suffix.hex}")
    folder_id  = var.folders[environment].id
  } }

  # Granted on the developers' folders, in addition to their other roles
  firebase_developer_roles = ["roles/firebase.developAdmin", "roles/firebase.growthAdmin", "roles/firebase.qualityAdmin"]
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
