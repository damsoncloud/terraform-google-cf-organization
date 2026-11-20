locals {
  # Least privilege: only the organisation policies cannot be granted on the projects. Granted by the authoritative organisation IAM policy (iam.tf), it lets the
  # disabler replace a project's policy for the `gcp.restrictServiceUsage` constraint
  billing_disabler_organization_role = "roles/orgpolicy.policyAdmin"

  # Granted by cf-gcp-project on each project with the billing disabler enabled, to read the project and detach it from its billing account
  billing_disabler_project_roles = [
    # keep-sorted start
    "roles/billing.projectManager",
    "roles/browser",
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

# cf-observability attaches the service account to the billing disabler's Cloud Run service as tf-bootstrap, which requires acting as it
resource "google_service_account_iam_member" "billing_disabler_deployer" {
  service_account_id = google_service_account.billing_disabler.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.tf_bootstrap_email}"
}
