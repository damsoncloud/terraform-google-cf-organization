data "google_project" "bootstrap" {
  project_id = var.bootstrap_project_id
}

locals {
  budget_projects = merge(
    {
      bootstrap      = { project_id = data.google_project.bootstrap.project_id, number = data.google_project.bootstrap.number, amount = var.budget_amounts.bootstrap }
      observability  = { project_id = google_project.observability.project_id, number = google_project.observability.number, amount = var.budget_amounts.observability }
      api_management = { project_id = google_project.api_management.project_id, number = google_project.api_management.number, amount = var.budget_amounts.api_management }
    },
    { for name, project in google_project.shared_vpc : "shared_vpc_${name}" => {
      project_id = project.project_id, number = project.number, amount = var.shared_vpc.host_projects[name].budget_amount
    } },
    var.apps_script == null ? {} : {
      apps_script = merge(module.apps_script[0].project, { amount = var.apps_script.budget_amount })
    },
    { for environment in keys(local.firebase_projects) : "firebase_${environment}" => merge(module.firebase[0].projects[environment], { amount = var.firebase.budget_amount }) },
  )
}

resource "google_monitoring_notification_channel" "billing" {
  project      = google_project.observability.project_id
  display_name = "Billing administrators"
  type         = "email"

  labels = {
    email_address = "${var.billing_admins_group_name}@${var.domain}"
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
      units = tostring(each.value.amount)
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
