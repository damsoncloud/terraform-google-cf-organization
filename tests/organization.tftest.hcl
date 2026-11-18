mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      email  = "billing-disabler@cmn-observability-c3d4.iam.gserviceaccount.com"
      member = "serviceAccount:billing-disabler@cmn-observability-c3d4.iam.gserviceaccount.com"
    }
  }

  # The policies' bindings are asserted on the data sources' arguments
  mock_data "google_iam_policy" {
    defaults = {
      policy_data = "{}"
    }
  }

  mock_data "google_project" {
    defaults = {
      project_id = "cmn-cf-bootstrap-a1b2"
      number     = "222222222222"
    }
  }
}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "c3d4"
    }
  }
}

variables {
  organization_id     = "123456789012"
  domain              = "example.com"
  environment_tag_key = "123456789012/environment"
  folders = {
    development   = { id = "folders/100000000001", short_name = "dev" }
    certification = { id = "folders/100000000002", short_name = "cert" }
    production    = { id = "folders/100000000003", short_name = "prod" }
    common        = { id = "folders/111111111111", short_name = "cmn", common = true }
    legacy        = { id = "folders/100000000004" }
  }
  billing_account                 = "012345-6789AB-CDEF01"
  bootstrap_project_id            = "cmn-cf-bootstrap-a1b2"
  tf_bootstrap_email              = "tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  tf_bootstrap_organization_roles = ["roles/resourcemanager.folderAdmin", "roles/resourcemanager.organizationViewer"]
  tf_plan_email                   = "tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  tf_plan_organization_roles      = ["roles/iam.securityReviewer", "roles/resourcemanager.organizationViewer"]
  tf_environment_emails = {
    development   = "tf-dev@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    certification = "tf-cert@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    production    = "tf-prod@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    common        = "tf-cmn@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
  }
}

run "generated_project_ids" {
  assert {
    condition     = output.observability_project_id == "cmn-observability-c3d4" && google_project.observability.name == "cmn-observability-c3d4"
    error_message = "The Observability project ID must be generated as cmn-observability-<suffix>."
  }

  assert {
    condition     = output.api_management_project_id == "cmn-api-management-hub-c3d4" && google_project.api_management.name == "cmn-api-management-hub-c3d4"
    error_message = "The API Management Hub project ID must be generated as cmn-api-management-hub-<suffix>."
  }
}

run "given_project_ids" {
  command = plan

  variables {
    observability_project_id  = "cmn-observability-6703"
    api_management_project_id = "cmn-api-management-hub-6703"
  }

  assert {
    condition     = google_project.observability.project_id == "cmn-observability-6703" && google_project.observability.name == "cmn-observability-6703"
    error_message = "A given Observability project ID must be used as the project's ID and name."
  }

  assert {
    condition     = google_project.api_management.project_id == "cmn-api-management-hub-6703" && google_project.api_management.name == "cmn-api-management-hub-6703"
    error_message = "A given API Management Hub project ID must be used as the project's ID and name."
  }
}

run "projects" {
  command = plan

  assert {
    condition = alltrue([for project in [google_project.observability, google_project.api_management] :
      project.folder_id == "folders/111111111111" && project.billing_account == "012345-6789AB-CDEF01" && !project.auto_create_network
    ])
    error_message = "The projects must be created in the folder, with the billing account and without the default network."
  }

  assert {
    condition     = keys(google_project_service.observability) == ["iam.googleapis.com", "monitoring.googleapis.com"]
    error_message = "The Observability project must have the IAM and Monitoring APIs enabled."
  }
}

run "billing_notification_channel" {
  assert {
    condition = (
      google_monitoring_notification_channel.billing.project == "cmn-observability-c3d4" &&
      google_monitoring_notification_channel.billing.type == "email" &&
      google_monitoring_notification_channel.billing.labels.email_address == "gcp-billing-admins@example.com"
    )
    error_message = "The billing notification channel must email the billing administrators group from the Observability project."
  }

  assert {
    condition     = output.billing_notification_channel == google_monitoring_notification_channel.billing.id
    error_message = "The billing notification channel must be returned as an output."
  }
}

run "billing_notification_channel_group" {
  command = plan

  variables {
    billing_admins_group_name = "finance"
  }

  assert {
    condition     = google_monitoring_notification_channel.billing.labels.email_address == "finance@example.com"
    error_message = "The billing notification channel must email the given billing administrators group."
  }
}

run "budgets" {
  variables {
    budget_amounts = {
      observability = 250
    }
  }

  assert {
    condition     = toset(keys(google_billing_budget.projects)) == toset(["bootstrap", "observability", "api_management", "apps_script"])
    error_message = "Each foundations' project must have a budget."
  }

  assert {
    condition = (
      google_billing_budget.projects["bootstrap"].budget_filter[0].projects == toset(["projects/222222222222"]) &&
      google_billing_budget.projects["observability"].budget_filter[0].projects == toset(["projects/${google_project.observability.number}"]) &&
      google_billing_budget.projects["api_management"].budget_filter[0].projects == toset(["projects/${google_project.api_management.number}"])
    )
    error_message = "Each budget must be filtered to its own project."
  }

  assert {
    condition = (
      google_billing_budget.projects["bootstrap"].amount[0].specified_amount[0].units == "100" &&
      google_billing_budget.projects["observability"].amount[0].specified_amount[0].units == "250" &&
      google_billing_budget.projects["api_management"].amount[0].specified_amount[0].units == "100"
    )
    error_message = "The budget amounts must default to 100 and be overridable per project."
  }

  assert {
    condition = alltrue([for budget in google_billing_budget.projects :
      budget.billing_account == "012345-6789AB-CDEF01" &&
      tolist([for rule in budget.threshold_rules : rule.threshold_percent]) == tolist([0.5, 0.7, 1.0]) &&
      budget.all_updates_rule[0].monitoring_notification_channels == tolist([google_monitoring_notification_channel.billing.id])
    ])
    error_message = "Each budget must alert only the billing notification channel, at 50%, 70% and 100%."
  }
}

run "billing_disabler" {
  assert {
    condition = (
      google_service_account.billing_disabler.project == "cmn-observability-c3d4" &&
      google_service_account.billing_disabler.account_id == "billing-disabler"
    )
    error_message = "The billing disabler service account must be created in the Observability project."
  }

  assert {
    condition = (
      google_billing_account_iam_member.billing_disabler.billing_account_id == "012345-6789AB-CDEF01" &&
      google_billing_account_iam_member.billing_disabler.role == "roles/billing.viewer" &&
      google_billing_account_iam_member.billing_disabler.member == "serviceAccount:billing-disabler@cmn-observability-c3d4.iam.gserviceaccount.com"
    )
    error_message = "The billing disabler must be able to read the budgets of the billing account."
  }

  assert {
    condition     = output.billing_disabler_project_roles == ["roles/billing.projectManager", "roles/browser"]
    error_message = "The billing disabler's project roles must be returned for cf-gcp-project."
  }

  assert {
    condition     = output.billing_disabler_email == "billing-disabler@cmn-observability-c3d4.iam.gserviceaccount.com"
    error_message = "The billing disabler email must be returned as an output."
  }
}

run "organization_iam" {
  variables {
    additional_organization_bindings = {
      "roles/securitycenter.serviceAgent"        = ["serviceAccount:service-org-123456789012@security-center-api.iam.gserviceaccount.com"]
      "roles/resourcemanager.organizationViewer" = ["group:auditors@example.com"]
    }
  }

  assert {
    condition = { for binding in data.google_iam_policy.organization.binding : binding.role => binding.members if length(binding.condition) == 0 } == {
      "roles/billing.admin"                     = toset(["group:gcp-billing-admins@example.com"])
      "roles/billing.creator"                   = toset(["group:gcp-billing-admins@example.com"])
      "roles/billing.user"                      = toset(["group:gcp-organization-admins@example.com"])
      "roles/iam.securityReviewer"              = toset(["serviceAccount:tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
      "roles/orgpolicy.policyAdmin"             = toset(["serviceAccount:billing-disabler@cmn-observability-c3d4.iam.gserviceaccount.com"])
      "roles/resourcemanager.folderAdmin"       = toset(["serviceAccount:tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
      "roles/resourcemanager.organizationAdmin" = toset(["group:gcp-organization-admins@example.com"])
      "roles/resourcemanager.projectCreator"    = toset(["group:gcp-organization-admins@example.com"])
      "roles/securitycenter.serviceAgent"       = toset(["serviceAccount:service-org-123456789012@security-center-api.iam.gserviceaccount.com"])
      "roles/resourcemanager.organizationViewer" = toset([
        "group:auditors@example.com",
        "serviceAccount:tf-bootstrap@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
        "serviceAccount:tf-plan@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com",
      ])
    }
    error_message = "The organisation policy must hold exactly the groups', deployers', billing disabler's and additional bindings."
  }

  assert {
    condition = {
      for binding in data.google_iam_policy.organization.binding : one(binding.condition).expression => binding.members
      if binding.role == "roles/resourcemanager.folderViewer"
      } == {
      "resource.matchTag('123456789012/environment', 'development')"   = toset(["group:gcp-dev-developers@example.com", "group:gcp-dev-sres@example.com", "group:gcp-dev-viewers@example.com"])
      "resource.matchTag('123456789012/environment', 'certification')" = toset(["group:gcp-cert-sres@example.com", "group:gcp-cert-viewers@example.com"])
      "resource.matchTag('123456789012/environment', 'production')"    = toset(["group:gcp-prod-sres@example.com", "group:gcp-prod-viewers@example.com"])
      "resource.matchTag('123456789012/environment', 'common')"        = toset(["group:gcp-cmn-sres@example.com", "group:gcp-cmn-viewers@example.com"])
      "resource.matchTag('123456789012/environment', 'legacy')"        = toset(["group:gcp-legacy-admins@example.com"])
    }
    error_message = "The groups granted roles on a folder must see that folder only."
  }

  assert {
    condition     = google_organization_iam_policy.organization.org_id == "123456789012"
    error_message = "The policy must be set on the organisation."
  }
}

run "audit_logs" {
  command = plan

  assert {
    condition = (
      one(data.google_iam_policy.organization.audit_config).service == "allServices" &&
      toset([for config in one(data.google_iam_policy.organization.audit_config).audit_log_configs : config.log_type]) == toset(["ADMIN_READ", "DATA_READ", "DATA_WRITE"])
    )
    error_message = "All Data Access audit logs must be enabled for all services by default."
  }
}

run "without_audit_logs" {
  command = plan

  variables {
    audit_log_types = []
  }

  assert {
    condition     = length(data.google_iam_policy.organization.audit_config) == 0
    error_message = "No audit log configuration must be set when audit_log_types is empty."
  }
}

run "folder_iam" {
  variables {
    additional_folder_bindings = {
      production = {
        "roles/reader" = ["group:auditors@example.com"]
      }
    }
  }

  assert {
    condition = { for binding in data.google_iam_policy.folders["development"].binding : binding.role => binding.members } == {
      "roles/iam.siteReliabilityEngineer"     = toset(["group:gcp-dev-sres@example.com"])
      "roles/reader"                          = toset(["group:gcp-dev-viewers@example.com"])
      "roles/iam.databasesAdmin"              = toset(["group:gcp-dev-developers@example.com"])
      "roles/iam.devOps"                      = toset(["group:gcp-dev-developers@example.com"])
      "roles/iam.infrastructureAdmin"         = toset(["group:gcp-dev-developers@example.com"])
      "roles/resourcemanager.projectIamAdmin" = toset(["serviceAccount:tf-dev@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
      "roles/writer"                          = toset(["serviceAccount:tf-dev@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
    }
    error_message = "The development folder must hold its groups', developers' and deployer's bindings."
  }

  assert {
    condition = { for binding in data.google_iam_policy.folders["production"].binding : binding.role => binding.members } == {
      "roles/iam.siteReliabilityEngineer"     = toset(["group:gcp-prod-sres@example.com"])
      "roles/reader"                          = toset(["group:auditors@example.com", "group:gcp-prod-viewers@example.com"])
      "roles/resourcemanager.projectIamAdmin" = toset(["serviceAccount:tf-prod@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
      "roles/writer"                          = toset(["serviceAccount:tf-prod@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"])
    }
    error_message = "The production folder must hold its groups', deployer's and additional bindings."
  }

  assert {
    condition = { for binding in data.google_iam_policy.folders["legacy"].binding : binding.role => binding.members } == {
      "roles/admin" = toset(["group:gcp-legacy-admins@example.com"])
    }
    error_message = "The legacy folder must hold only the legacy administrators' bindings."
  }

  assert {
    condition = alltrue([for folder, policy in google_folder_iam_policy.folders :
      policy.folder == var.folders[folder].id && policy.policy_data == data.google_iam_policy.folders[folder].policy_data
    ])
    error_message = "Each folder must get its own policy."
  }
}

run "legacy_admins_group" {
  command = plan

  variables {
    legacy_admins_group_name = "legacy-owners"
  }

  assert {
    condition = { for binding in data.google_iam_policy.folders["legacy"].binding : binding.role => binding.members } == {
      "roles/admin" = toset(["group:legacy-owners@example.com"])
    }
    error_message = "The legacy folder must be administered by the given group."
  }
}

run "invalid_folders" {
  command = plan

  variables {
    folders = {
      common = { id = "111111111111", short_name = "cmn", common = true }
    }
    tf_environment_emails = {}
    folder_group_roles    = {}
  }

  expect_failures = [var.folders]
}

run "renamed_common_environment" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
      shared      = { id = "folders/122222222222", short_name = "shr", common = true }
    }
    tf_environment_emails = {}
  }

  assert {
    condition = alltrue([for project in [google_project.observability, google_project.api_management] :
      project.folder_id == "folders/122222222222"
    ])
    error_message = "The projects must be created in the common environment's folder."
  }

  assert {
    condition = (
      google_project.observability.project_id == "shr-observability-c3d4" &&
      google_project.api_management.project_id == "shr-api-management-hub-c3d4"
    )
    error_message = "The generated project IDs must start with the common environment's short name."
  }
}

run "generated_project_id_too_long" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
      common      = { id = "folders/111111111111", short_name = "common-env", common = true }
    }
    tf_environment_emails = {}
  }

  expect_failures = [google_project.api_management]
}

run "no_common_environment" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
    }
    tf_environment_emails = {}
  }

  expect_failures = [var.folders]
}

run "several_common_environments" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
      common      = { id = "folders/111111111111", short_name = "cmn", common = true }
      shared      = { id = "folders/122222222222", short_name = "shr", common = true }
    }
    tf_environment_emails = {}
  }

  expect_failures = [var.folders]
}

run "common_environment_without_short_name" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
      common      = { id = "folders/111111111111", common = true }
    }
    tf_environment_emails = {}
  }

  expect_failures = [var.folders]
}

run "duplicate_short_names" {
  command = plan

  variables {
    folders = {
      development = { id = "folders/100000000001", short_name = "dev" }
      demo        = { id = "folders/100000000002", short_name = "dev" }
      common      = { id = "folders/111111111111", short_name = "cmn", common = true }
    }
    tf_environment_emails = {}
  }

  expect_failures = [var.folders]
}

run "unknown_deployer_folder" {
  command = plan

  variables {
    tf_environment_emails = {
      staging = "tf-stg@cmn-cf-bootstrap-a1b2.iam.gserviceaccount.com"
    }
  }

  expect_failures = [var.tf_environment_emails]
}

run "unknown_group_folder" {
  command = plan

  variables {
    folder_group_roles = {
      staging = {
        gcp-stg-developers = ["roles/iam.devOps"]
      }
    }
  }

  expect_failures = [var.folder_group_roles]
}

run "unknown_additional_binding_folder" {
  command = plan

  variables {
    additional_folder_bindings = {
      staging = {
        "roles/reader" = ["group:auditors@example.com"]
      }
    }
  }

  expect_failures = [var.additional_folder_bindings]
}

run "invalid_organization_id" {
  command = plan

  variables {
    organization_id = "organizations/123456789012"
  }

  expect_failures = [var.organization_id]
}

run "invalid_environment_tag_key" {
  command = plan

  variables {
    environment_tag_key = "tagKeys/123"
  }

  expect_failures = [var.environment_tag_key]
}

run "invalid_domain" {
  command = plan

  variables {
    domain = "Example"
  }

  expect_failures = [var.domain]
}

run "invalid_audit_log_type" {
  command = plan

  variables {
    audit_log_types = ["ADMIN_WRITE"]
  }

  expect_failures = [var.audit_log_types]
}

run "invalid_billing_account" {
  command = plan

  variables {
    billing_account = "012345-6789ab-cdef01"
  }

  expect_failures = [var.billing_account]
}

run "invalid_observability_project_id" {
  command = plan

  variables {
    observability_project_id = "Cmn-observability"
  }

  expect_failures = [var.observability_project_id]
}

run "invalid_api_management_project_id" {
  command = plan

  variables {
    api_management_project_id = "cmn-api-management-hub-6703-"
  }

  expect_failures = [var.api_management_project_id]
}

run "invalid_budget_amount" {
  command = plan

  variables {
    budget_amounts = {
      bootstrap = 0
    }
  }

  expect_failures = [var.budget_amounts]
}

run "model_armor" {
  command = plan

  assert {
    condition = (
      google_model_armor_floorsetting.organization.parent == "organizations/123456789012" &&
      google_model_armor_floorsetting.organization.location == "global" &&
      google_model_armor_floorsetting.organization.enable_floor_setting_enforcement
    )
    error_message = "The floor setting must be enforced on the organisation."
  }

  assert {
    condition = (
      { for filter in google_model_armor_floorsetting.organization.filter_config[0].rai_settings[0].rai_filters : filter.filter_type => filter.confidence_level } == {
        DANGEROUS         = "MEDIUM_AND_ABOVE"
        HARASSMENT        = "MEDIUM_AND_ABOVE"
        HATE_SPEECH       = "MEDIUM_AND_ABOVE"
        SEXUALLY_EXPLICIT = "MEDIUM_AND_ABOVE"
      } &&
      google_model_armor_floorsetting.organization.filter_config[0].pi_and_jailbreak_filter_settings[0].filter_enforcement == "ENABLED" &&
      google_model_armor_floorsetting.organization.filter_config[0].pi_and_jailbreak_filter_settings[0].confidence_level == "MEDIUM_AND_ABOVE" &&
      google_model_armor_floorsetting.organization.filter_config[0].malicious_uri_filter_settings[0].filter_enforcement == "ENABLED" &&
      google_model_armor_floorsetting.organization.filter_config[0].sdp_settings[0].basic_config[0].filter_enforcement == "ENABLED" &&
      google_model_armor_floorsetting.organization.floor_setting_metadata[0].multi_language_detection[0].enable_multi_language_detection
    )
    error_message = "All filters must be enabled at medium confidence by default."
  }

  assert {
    condition = (
      google_model_armor_floorsetting.organization.integrated_services == null &&
      length(google_model_armor_floorsetting.organization.ai_platform_floor_setting) == 0 &&
      length(google_model_armor_floorsetting.organization.google_mcp_server_floor_setting) == 0
    )
    error_message = "The integrated services must not be set on the organisation, as they are project-level only."
  }

  assert {
    condition     = output.model_armor.confidence_level == "MEDIUM_AND_ABOVE" && length(output.model_armor.responsible_ai_filters) == 4
    error_message = "The floor setting's filters must be returned with their defaults."
  }

  assert {
    condition     = !contains(keys(output.model_armor), "enforcement")
    error_message = "The organisation's enforcement must not be returned, as each project enables its own."
  }
}

run "model_armor_reduced" {
  command = plan

  variables {
    model_armor = {
      confidence_level          = "HIGH"
      responsible_ai_filters    = []
      malicious_uri             = false
      sensitive_data_protection = false
    }
  }

  assert {
    condition = (
      length(google_model_armor_floorsetting.organization.filter_config[0].rai_settings) == 0 &&
      google_model_armor_floorsetting.organization.filter_config[0].pi_and_jailbreak_filter_settings[0].confidence_level == "HIGH" &&
      google_model_armor_floorsetting.organization.filter_config[0].malicious_uri_filter_settings[0].filter_enforcement == "DISABLED" &&
      google_model_armor_floorsetting.organization.filter_config[0].sdp_settings[0].basic_config[0].filter_enforcement == "DISABLED"
    )
    error_message = "The filters must follow the model_armor input."
  }
}

run "invalid_model_armor_confidence_level" {
  command = plan

  variables {
    model_armor = {
      confidence_level = "MEDIUM"
    }
  }

  expect_failures = [var.model_armor]
}

run "invalid_model_armor_filter" {
  command = plan

  variables {
    model_armor = {
      responsible_ai_filters = ["VIOLENCE"]
    }
  }

  expect_failures = [var.model_armor]
}

run "apps_script_by_default" {
  assert {
    condition = (
      output.apps_script_project.project_id == "cmn-apps-script-c3d4" &&
      module.apps_script[0].project.project_id == "cmn-apps-script-c3d4"
    )
    error_message = "The Apps Script project must be created by default, with a generated ID."
  }

  assert {
    condition = (
      google_billing_budget.projects["apps_script"].amount[0].specified_amount[0].units == "10" &&
      google_billing_budget.projects["apps_script"].budget_filter[0].projects == toset(["projects/${output.apps_script_project.number}"])
    )
    error_message = "The Apps Script project must have a budget of 10 by default."
  }

  assert {
    condition     = length(module.firebase) == 0 && output.firebase_projects == {} && output.firebase_apis == []
    error_message = "No Firebase project must be created by default."
  }
}

run "without_apps_script" {
  command = plan

  variables {
    apps_script = null
  }

  assert {
    condition     = length(module.apps_script) == 0 && output.apps_script_project == null && !contains(keys(google_billing_budget.projects), "apps_script")
    error_message = "No Apps Script project or budget must be created when apps_script is null."
  }
}

run "firebase" {
  variables {
    firebase = {
      project_ids   = { production = "prod-firebase-6703" }
      budget_amount = 200
    }
  }

  assert {
    condition = { for environment, project in output.firebase_projects : environment => project.project_id } == {
      development   = "dev-firebase-c3d4"
      certification = "cert-firebase-c3d4"
      production    = "prod-firebase-6703"
    }
    error_message = "Each environment but the common one must get a Firebase project, with a generated or given ID."
  }

  assert {
    condition = alltrue([for environment in ["development", "certification", "production"] :
      google_billing_budget.projects["firebase_${environment}"].amount[0].specified_amount[0].units == "200"
    ])
    error_message = "Each Firebase project must have a budget."
  }

  assert {
    condition = { for binding in data.google_iam_policy.folders["development"].binding : binding.role => binding.members if startswith(binding.role, "roles/firebase.") } == {
      "roles/firebase.developAdmin" = toset(["group:gcp-dev-developers@example.com"])
      "roles/firebase.growthAdmin"  = toset(["group:gcp-dev-developers@example.com"])
      "roles/firebase.qualityAdmin" = toset(["group:gcp-dev-developers@example.com"])
    }
    error_message = "The developers must be granted the Firebase roles on the development folder only."
  }

  assert {
    condition     = length([for binding in data.google_iam_policy.folders["production"].binding : binding if startswith(binding.role, "roles/firebase.")]) == 0
    error_message = "No Firebase role must be granted on the other folders."
  }

  assert {
    condition     = contains(output.firebase_apis, "firestore.googleapis.com")
    error_message = "The Firebase APIs must be returned for the org-policies submodule."
  }
}

run "firebase_development_only" {
  command = plan

  variables {
    firebase = {
      environments = ["development"]
    }
  }

  assert {
    condition     = keys(local.firebase_projects) == ["development"]
    error_message = "Only the listed environments must get a Firebase project."
  }
}

run "firebase_in_common_environment" {
  command = plan

  variables {
    firebase = {
      environments = ["common"]
    }
  }

  expect_failures = [var.firebase]
}

run "invalid_apps_script_budget" {
  command = plan

  variables {
    apps_script = {
      budget_amount = 0
    }
  }

  expect_failures = [var.apps_script]
}
