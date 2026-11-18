locals {
  # Granted by the authoritative organisation IAM policy: the disabler reads the projects in a budget's filter, detaches them from their billing account and replaces their
  # project-level policy for the `gcp.restrictServiceUsage` constraint
  billing_disabler_organization_roles = [
    # keep-sorted start
    "roles/billing.projectManager",
    "roles/browser",
    "roles/orgpolicy.policyAdmin",
    # keep-sorted end
  ]
}

# Runs the billing disabler deployed by cf-observability
resource "google_service_account" "billing_disabler" {
  project      = google_project.observability.project_id
  account_id   = "billing-disabler"
  display_name = "Billing disabler"

  depends_on = [google_project_service.observability]
}

# Reads the budgets
resource "google_billing_account_iam_member" "billing_disabler" {
  billing_account_id = var.billing_account
  role               = "roles/billing.viewer"
  member             = google_service_account.billing_disabler.member
}
