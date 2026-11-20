module "hierarchy" {
  source  = "damsoncloud/cf-hierarchy/google"
  version = "0.2.0"

  organization_id = var.organization_id
}

module "bootstrap" {
  source  = "damsoncloud/cf-bootstrap/google"
  version = "0.4.0"

  organization_id = var.organization_id
  folders         = module.hierarchy.folders
  billing_account = var.billing_account
}

module "organization" {
  source = "../.."

  organization_id     = var.organization_id
  domain              = var.domain
  environment_tag_key = module.hierarchy.environment_tag_key_namespaced_name
  folders             = module.hierarchy.folders
  billing_account     = var.billing_account

  bootstrap_project_id            = module.bootstrap.project_id
  tf_bootstrap_email              = module.bootstrap.tf_bootstrap_email
  tf_bootstrap_organization_roles = module.bootstrap.tf_bootstrap_organization_roles
  tf_plan_email                   = module.bootstrap.tf_plan_email
  tf_plan_organization_roles      = module.bootstrap.tf_plan_organization_roles
  tf_environment_emails           = module.bootstrap.tf_environment_emails

  firebase = {
    environments = ["development"]
  }
}

module "org_policies" {
  source = "../../modules/org-policies"

  organization_id   = var.organization_id
  mode              = var.mode
  allowed_locations = ["in:europe-west4-locations", "in:europe-west1-locations"]
  legacy_folder_id  = module.hierarchy.folders["legacy"].id
  api_management = {
    project_id = module.organization.api_management_project_id
  }
  firebase = {
    project_ids      = [for project in values(module.organization.firebase_projects) : project.project_id]
    allowed_services = module.organization.firebase_apis
  }
}

module "vpc_service_controls" {
  source = "../../modules/vpc-service-controls"

  organization_id = var.organization_id
  mode            = var.mode
  projects = {
    bootstrap      = module.bootstrap.project_number
    observability  = module.organization.observability_project_number
    api_management = module.organization.api_management_project_number
    apps_script    = module.organization.apps_script_project.number
  }
  deployers = concat(
    [module.bootstrap.tf_bootstrap_email, module.bootstrap.tf_plan_email],
    values(module.bootstrap.tf_environment_emails),
  )
  groups = module.organization.perimeter_groups
}
