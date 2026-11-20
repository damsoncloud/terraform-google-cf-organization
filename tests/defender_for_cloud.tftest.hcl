# Tests of the modules/defender-for-cloud submodule, without the root tests' fixed service account emails
mock_provider "google" {}

variables {
  organization_id = "123456789012"
  project_id      = "cmn-observability-c3d4"
}

run "defender_for_cloud" {
  module {
    source = "./modules/defender-for-cloud"
  }

  assert {
    condition = (
      length(google_service_account.defender_for_cloud) == 11 &&
      contains(keys(output.service_accounts), "microsoft-defender-cspm") &&
      alltrue([for account in google_service_account.defender_for_cloud : account.project == "cmn-observability-c3d4"])
    )
    error_message = "The Defender for Cloud service accounts must be created in the given project."
  }

  assert {
    condition = (
      length(google_organization_iam_custom_role.defender_for_cloud) == 9 &&
      alltrue([for role in google_organization_iam_custom_role.defender_for_cloud : role.org_id == "123456789012"]) &&
      output.log_collection_role == google_organization_iam_custom_role.defender_for_cloud["mdc-log-collection"].id
    )
    error_message = "The Defender for Cloud custom roles must be created in the organisation."
  }

  assert {
    condition = (
      length(output.organization_bindings) == 23 &&
      contains(output.organization_bindings, { role = "roles/reader", member = google_service_account.defender_for_cloud["microsoft-defender-cspm"].member }) &&
      contains(output.organization_bindings, {
        role   = google_organization_iam_custom_role.defender_for_cloud["microsoft-defender-cspm"].id
        member = google_service_account.defender_for_cloud["microsoft-defender-cspm"].member
      }) &&
      contains(output.organization_bindings, {
        role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        member = "serviceAccount:service-220551266886@compute-system.iam.gserviceaccount.com"
      })
    )
    error_message = "The service accounts must get their custom and further organisation roles, and Microsoft's identities their agentless scanning roles."
  }

  assert {
    condition = output.external_members == [
      "serviceAccount:mdc-agentless-scanning@guardians-prod-diskscanning.iam.gserviceaccount.com",
      "serviceAccount:service-220551266886@compute-system.iam.gserviceaccount.com",
    ]
    error_message = "Microsoft's identities must be returned for the org-policies submodule."
  }
}
