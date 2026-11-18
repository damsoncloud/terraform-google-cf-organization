mock_provider "google" {
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
  folder_id            = "folders/111111111111"
  billing_account      = "012345-6789AB-CDEF01"
  billing_admins_group = "gcp-billing-admins@example.com"
  bootstrap_project_id = "cmn-cf-bootstrap-a1b2"
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
    condition     = keys(google_project_service.observability) == ["monitoring.googleapis.com"]
    error_message = "The Observability project must have the Monitoring API enabled."
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

run "budgets" {
  variables {
    budget_amounts = {
      observability = 250
    }
  }

  assert {
    condition     = toset(keys(google_billing_budget.projects)) == toset(["bootstrap", "observability", "api_management"])
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

run "invalid_folder_id" {
  command = plan

  variables {
    folder_id = "111111111111"
  }

  expect_failures = [var.folder_id]
}

run "invalid_billing_account" {
  command = plan

  variables {
    billing_account = "012345-6789ab-cdef01"
  }

  expect_failures = [var.billing_account]
}

run "invalid_billing_admins_group" {
  command = plan

  variables {
    billing_admins_group = "gcp-billing-admins"
  }

  expect_failures = [var.billing_admins_group]
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
