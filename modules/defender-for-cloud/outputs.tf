output "organization_bindings" {
  description = "The organisation roles of the service accounts and of Microsoft's agentless scanning identities, for the authoritative organisation IAM policy."
  value = concat(
    [for name, role in google_organization_iam_custom_role.defender_for_cloud : { role = role.id, member = google_service_account.defender_for_cloud[name].member }],
    flatten([for name, account in local.service_accounts : [
      for role in account.org_level_roles_membership : { role = role, member = google_service_account.defender_for_cloud[name].member }
    ]]),
    [
      { role = google_organization_iam_custom_role.agentless_scanning.id, member = local.agentless_scanning_member },
      { role = "roles/cloudkms.cryptoKeyEncrypterDecrypter", member = local.disk_decryption_member },
    ],
  )
}

output "service_accounts" {
  description = "Emails of the service accounts by name."
  value       = { for name, account in google_service_account.defender_for_cloud : name => account.email }
}

output "log_collection_role" {
  description = "ID of the custom role consuming the audit log subscription, granted on it by cf-observability."
  value       = google_organization_iam_custom_role.defender_for_cloud["mdc-log-collection"].id
}

output "external_members" {
  description = "Microsoft's identities outside the organisation, to allow in the `iam.managed.allowedPolicyMembers` constraint."
  value       = [local.agentless_scanning_member, local.disk_decryption_member]
}
