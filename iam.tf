locals {
  organization_members = concat(
    flatten([for group, roles in var.organization_group_roles : [for role in roles : { role = role, member = "group:${group}@${var.domain}" }]]),
    [for role in var.tf_bootstrap_organization_roles : { role = role, member = "serviceAccount:${var.tf_bootstrap_email}" }],
    [for role in var.tf_plan_organization_roles : { role = role, member = "serviceAccount:${var.tf_plan_email}" }],
    [{ role = local.billing_disabler_organization_role, member = google_service_account.billing_disabler.member }],
    flatten([for role, members in var.additional_organization_bindings : [for member in members : { role = role, member = member }]]),
    flatten(module.defender_for_cloud[*].organization_bindings),
  )

  folder_members = { for folder in keys(var.folders) : folder => concat(
    flatten([for suffix, roles in var.environment_group_roles : [
      for role in roles : { role = role, member = "group:gcp-${local.environments[folder]}-${suffix}@${var.domain}" }
    ] if contains(keys(local.environments), folder)]),
    flatten([for group, roles in lookup(var.folder_group_roles, folder, {}) : [for role in roles : { role = role, member = "group:${group}@${var.domain}" }]]),
    [for role in local.firebase_developer_roles : {
      role = role, member = "group:${var.firebase.developers[folder]}@${var.domain}"
    } if var.firebase != null && contains(keys(try(var.firebase.developers, {})), folder)],
    [for role in var.environment_deployer_roles : {
      role = role, member = "serviceAccount:${var.tf_environment_emails[folder]}"
    } if contains(keys(var.tf_environment_emails), folder)],
    [for role in var.legacy_admins_roles : { role = role, member = "group:${var.legacy_admins_group_name}@${var.domain}" } if folder == "legacy"],
    flatten([for role, members in lookup(var.additional_folder_bindings, folder, {}) : [for member in members : { role = role, member = member }]]),
  ) }

  # The groups granted roles on a folder, which need to see it from the organisation, e.g. in the console
  folder_viewer_groups = {
    for folder, members in local.folder_members : folder => sort(distinct([for member in members : member.member if startswith(member.member, "group:")]))
    if anytrue([for member in members : startswith(member.member, "group:")])
  }
}

# Authoritative: removes every binding and audit log configuration not declared here
data "google_iam_policy" "organization" {
  dynamic "audit_config" {
    for_each = length(var.audit_log_types) > 0 ? ["allServices"] : []

    content {
      service = audit_config.value

      dynamic "audit_log_configs" {
        for_each = toset(var.audit_log_types)

        content {
          log_type = audit_log_configs.value
        }
      }
    }
  }

  dynamic "binding" {
    for_each = { for member in local.organization_members : member.role => member.member... }

    content {
      role    = binding.key
      members = sort(distinct(binding.value))
    }
  }

  # Limited by the folders' `environment` tag values, named after the folders
  dynamic "binding" {
    for_each = local.folder_viewer_groups

    content {
      role    = "roles/resourcemanager.folderViewer"
      members = binding.value

      condition {
        title      = "${binding.key} folder"
        expression = "resource.matchTag('${var.environment_tag_key}', '${binding.key}')"
      }
    }
  }
}

resource "google_organization_iam_policy" "organization" {
  org_id      = var.organization_id
  policy_data = data.google_iam_policy.organization.policy_data
}

# Authoritative: removes every binding not declared here
data "google_iam_policy" "folders" {
  for_each = var.folders

  dynamic "binding" {
    for_each = { for member in local.folder_members[each.key] : member.role => member.member... }

    content {
      role    = binding.key
      members = sort(distinct(binding.value))
    }
  }
}

resource "google_folder_iam_policy" "folders" {
  for_each = var.folders

  folder      = each.value.id
  policy_data = data.google_iam_policy.folders[each.key].policy_data
}
