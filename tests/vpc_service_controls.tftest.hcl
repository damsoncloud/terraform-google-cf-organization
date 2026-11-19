# Tests of the modules/vpc-service-controls submodule, called directly
mock_provider "google" {
  mock_resource "google_access_context_manager_access_policy" {
    defaults = {
      name = "555555555555"
    }
  }

  mock_resource "google_access_context_manager_service_perimeter" {
    defaults = {
      name = "accessPolicies/555555555555/servicePerimeters/cloud_foundations_production"
    }
  }
}

variables {
  organization_id = "123456789012"
  mode            = "enforced"
  projects = {
    bootstrap     = "222222222222"
    observability = "333333333333"
  }
  deployers = [
    "tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
    "tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
  ]
}

run "enforced" {
  module {
    source = "./modules/vpc-service-controls"
  }

  assert {
    condition = (
      google_access_context_manager_access_policy.organization[0].parent == "organizations/123456789012" &&
      google_access_context_manager_service_perimeter.foundations.parent == "accessPolicies/555555555555" &&
      google_access_context_manager_service_perimeter.foundations.name == "accessPolicies/555555555555/servicePerimeters/cloud_foundations_production" &&
      google_access_context_manager_service_perimeter.foundations.title == "Cloud Foundations and production" &&
      google_access_context_manager_service_perimeter.foundations.perimeter_type == "PERIMETER_TYPE_REGULAR" &&
      google_access_context_manager_service_perimeter.foundations.use_explicit_dry_run_spec
    )
    error_message = "A regular perimeter with an explicit dry-run configuration must be created in a new organisation access policy."
  }

  assert {
    condition = (
      length(google_access_context_manager_service_perimeter.foundations.status[0].restricted_services) == 74 &&
      google_access_context_manager_service_perimeter.foundations.status[0].restricted_services == google_access_context_manager_service_perimeter.foundations.spec[0].restricted_services &&
      contains(google_access_context_manager_service_perimeter.foundations.status[0].restricted_services, "storage.googleapis.com") &&
      !contains(google_access_context_manager_service_perimeter.foundations.status[0].restricted_services, "iam.googleapis.com")
    )
    error_message = "The enforced and dry-run configurations must restrict the generally available supported services."
  }

  assert {
    condition = (
      toset(keys(google_access_context_manager_service_perimeter_ingress_policy.rules)) == toset(["Deployers", "Cloud Billing budget notifications"]) &&
      keys(google_access_context_manager_service_perimeter_dry_run_ingress_policy.rules) == keys(google_access_context_manager_service_perimeter_ingress_policy.rules) &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Deployers"].perimeter == output.perimeter_name &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Deployers"].ingress_from[0].identities == tolist([
        "serviceAccount:tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
        "serviceAccount:tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
      ]) &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Deployers"].ingress_from[0].sources[0].access_level == "*" &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Deployers"].ingress_to[0].operations[0].service_name == "*" &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Cloud Billing budget notifications"].ingress_to[0].operations[0].method_selectors[0].method == "google.pubsub.v1.Publisher.Publish"
    )
    error_message = "The deployers must access the perimeter from any source, and Cloud Billing must publish budget notifications."
  }

  assert {
    condition = (
      { for key, member in google_access_context_manager_service_perimeter_resource.projects : key => member.resource } == { bootstrap = "projects/222222222222", observability = "projects/333333333333" } &&
      { for key, member in google_access_context_manager_service_perimeter_dry_run_resource.projects : key => member.resource } == { bootstrap = "projects/222222222222", observability = "projects/333333333333" }
    )
    error_message = "Each project must be added to both configurations."
  }

  assert {
    condition     = output.access_policy_id == "555555555555" && output.perimeter_name == "accessPolicies/555555555555/servicePerimeters/cloud_foundations_production"
    error_message = "The access policy and the perimeter must be returned."
  }
}

run "dry_run" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    mode = "dry_run"
  }

  assert {
    condition = (
      length(google_access_context_manager_service_perimeter.foundations.status[0].restricted_services) == 0 &&
      length(google_access_context_manager_service_perimeter_ingress_policy.rules) == 0 &&
      length(google_access_context_manager_service_perimeter.foundations.spec[0].restricted_services) == 74 &&
      length(google_access_context_manager_service_perimeter_dry_run_ingress_policy.rules) == 2
    )
    error_message = "In dry-run mode, only the dry-run configuration must restrict services and hold the rules."
  }

  assert {
    condition     = length(google_access_context_manager_service_perimeter_resource.projects) == 2 && length(google_access_context_manager_service_perimeter_dry_run_resource.projects) == 2
    error_message = "The projects must be added to both configurations in dry-run mode too."
  }
}

run "existing_access_policy_and_rules" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    access_policy_id               = "777777777777"
    perimeter_name                 = "foundations"
    additional_restricted_services = ["iam.googleapis.com"]
    deployers                      = []
    access_levels = {
      office = { ip_subnetworks = ["203.0.113.0/24"] }
    }
    ingress_policies = [{
      title                = "Office"
      identity_type        = "ANY_USER_ACCOUNT"
      source_access_levels = ["office"]
      operations           = { "bigquery.googleapis.com" = [] }
    }]
    egress_policies = [{
      title      = "Partner bucket"
      identities = ["serviceAccount:etl@cmn-observability-c3d4.iam.gserviceaccount.com"]
      resources  = ["projects/888888888888"]
      operations = { "storage.googleapis.com" = ["google.storage.objects.get"] }
    }]
  }

  assert {
    condition = (
      length(google_access_context_manager_access_policy.organization) == 0 &&
      google_access_context_manager_service_perimeter.foundations.name == "accessPolicies/777777777777/servicePerimeters/foundations" &&
      google_access_context_manager_access_level.levels["office"].name == "accessPolicies/777777777777/accessLevels/office"
    )
    error_message = "The perimeter and access levels must be created in the given access policy, without creating one."
  }

  assert {
    condition = (
      contains(google_access_context_manager_service_perimeter.foundations.status[0].restricted_services, "iam.googleapis.com") &&
      toset(keys(google_access_context_manager_service_perimeter_ingress_policy.rules)) == toset(["Cloud Billing budget notifications", "Office"]) &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Office"].ingress_from[0].sources[0].access_level == "accessPolicies/777777777777/accessLevels/office" &&
      google_access_context_manager_service_perimeter_ingress_policy.rules["Office"].ingress_to[0].operations[0].method_selectors[0].method == "*" &&
      google_access_context_manager_service_perimeter.foundations.status[0].egress_policies[0].egress_to[0].resources == toset(["projects/888888888888"])
    )
    error_message = "The additional services, access levels, ingress and egress rules must follow the inputs."
  }
}

run "invalid_mode" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    mode = "enforce"
  }

  expect_failures = [var.mode]
}

run "invalid_project" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    projects = { bootstrap = "cmn-cf-bootstrap-a1b2" }
  }

  expect_failures = [var.projects]
}

run "invalid_perimeter_name" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    perimeter_name = "cloud-foundations"
  }

  expect_failures = [var.perimeter_name]
}

run "duplicate_ingress_policy_title" {
  command = plan

  module {
    source = "./modules/vpc-service-controls"
  }

  variables {
    ingress_policies = [{ title = "Deployers", identity_type = "ANY_IDENTITY", source_access_levels = ["*"] }]
  }

  expect_failures = [var.ingress_policies]
}
