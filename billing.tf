data "google_project" "bootstrap" {
  project_id = var.bootstrap_project_id
}

locals {
  budget_projects = {
    bootstrap      = data.google_project.bootstrap
    observability  = google_project.observability
    api_management = google_project.api_management
  }
}

resource "google_monitoring_notification_channel" "billing" {
  project      = google_project.observability.project_id
  display_name = "Billing administrators"
  type         = "email"

  labels = {
    email_address = var.billing_admins_group
  }

  depends_on = [google_project_service.observability]
}

resource "google_billing_budget" "projects" {
  for_each = local.budget_projects

  billing_account = var.billing_account
  display_name    = each.value.project_id

  budget_filter {
    projects = ["projects/${each.value.number}"]
  }

  # Without a currency code, the amount is in the billing account's currency
  amount {
    specified_amount {
      units = tostring(var.budget_amounts[each.key])
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.7, 1.0]

    content {
      threshold_percent = threshold_rules.value
    }
  }

  # The billing administrators group is notified through the channel instead
  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.billing.id]
  }
}
