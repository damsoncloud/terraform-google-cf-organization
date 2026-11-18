locals {
  organization = "organizations/${var.organization_id}"

  # Default values of a policy, so that all policies have the same type
  policy = {
    enforce             = tobool(null)
    parameters          = tostring(null)
    allow               = tolist([])
    deny                = tolist([])
    allow_all           = false
    deny_all            = false
    inherit_from_parent = false
  }

  baseline = merge(
    # Managed constraints, enforced without parameters
    { for constraint in [
      # keep-sorted start
      "compute.managed.blockPreviewFeatures",
      "compute.managed.blockProjectSshKeys",
      "compute.managed.disableSerialPortAccess",
      "compute.managed.vmExternalIpAccess",
      "dataflow.managed.disableUsePublicIps",
      "iam.managed.disableServiceAccountApiKeyCreation",
      "iam.managed.disableServiceAccountKeyCreation",
      "iam.managed.disableServiceAccountKeyUpload",
      "iam.managed.preventPrivilegedBasicRolesForDefaultServiceAccounts",
      # keep-sorted end
    ] : constraint => merge(local.policy, { enforce = true }) },
    # Legacy boolean constraints, without dry-run
    { for constraint in [
      "compute.skipDefaultNetworkCreation",
      "storage.uniformBucketLevelAccess",
    ] : constraint => merge(local.policy, { enforce = true }) },
    {
      "spanner.managed.restrictCloudSpannerEditions" = merge(local.policy, {
        enforce    = true
        parameters = jsonencode({ deniedEditions = ["ENTERPRISE", "ENTERPRISE_PLUS"] })
      })

      # The organisation's principal set covers its users, groups, service accounts and service agents; Cloud Billing grants its own account the Publisher role on the
      # topics of budget notifications, e.g. the billing disabler's
      "iam.managed.allowedPolicyMembers" = merge(local.policy, {
        enforce = true
        parameters = jsonencode({
          allowedMemberSubjects = concat(["serviceAccount:billing-budget-alert@system.gserviceaccount.com"], var.additional_allowed_members)
          allowedPrincipalSets  = concat(["//cloudresourcemanager.googleapis.com/${local.organization}"], var.additional_allowed_principal_sets)
        })
      })

      "gcp.restrictServiceUsage" = merge(local.policy, { allow = distinct(concat(var.allowed_services, var.additional_allowed_services)) })
      "gcp.resourceLocations"    = merge(local.policy, { allow = var.allowed_locations })
      "compute.restrictVpcPeering" = merge(local.policy, {
        allow    = var.allowed_vpc_peering_networks
        deny_all = length(var.allowed_vpc_peering_networks) == 0
      })
    },
    var.shared_vpc_host_folder_id == null ? {} : {
      "compute.restrictSharedVpcHostProjects" = merge(local.policy, { allow = ["under:${var.shared_vpc_host_folder_id}"] })
    },
  )

  exceptions = merge(
    var.legacy_folder_id == null ? {} : {
      "${var.legacy_folder_id}/gcp.restrictServiceUsage" = merge(local.policy, {
        parent    = var.legacy_folder_id
        allow_all = true
      })
      "${var.legacy_folder_id}/iam.managed.disableServiceAccountKeyCreation" = merge(local.policy, {
        parent  = var.legacy_folder_id
        enforce = false
      })
    },
    var.api_management == null ? {} : {
      "projects/${var.api_management.project_id}/gcp.restrictServiceUsage" = merge(local.policy, {
        parent              = "projects/${var.api_management.project_id}"
        allow               = var.api_management.allowed_services
        inherit_from_parent = true
      })
    },
  )

  additional = { for policy in var.additional_policies : "${coalesce(policy.parent, local.organization)}/${policy.constraint}" => merge(local.policy, {
    parent              = coalesce(policy.parent, local.organization)
    enforce             = policy.enforce
    parameters          = policy.parameters
    allow               = policy.allow
    deny                = policy.deny
    allow_all           = policy.allow_all
    deny_all            = policy.deny_all
    inherit_from_parent = policy.inherit_from_parent
  }) }

  # Keyed by `<parent>/<constraint>`; the additional policies replace the baseline's and the exceptions
  all_policies = { for key, policy in merge(
    {
      for constraint, policy in local.baseline : "${local.organization}/${constraint}" => merge(policy, { parent = local.organization })
      if !contains(var.disabled_constraints, constraint)
    },
    local.exceptions,
    local.additional,
  ) : key => merge(policy, { constraint = element(split("/", key), 2) }) }

  # Managed and custom constraints support dry-run, and four legacy ones
  dry_run_constraints = ["gcp.restrictServiceUsage", "gcp.restrictEndpointUsage", "gcp.restrictTLSVersion", "gcp.restrictTLSCipherSuites"]
  policies = { for key, policy in local.all_policies : key => policy if var.mode == "enforced" || (
    strcontains(policy.constraint, ".managed.") || startswith(policy.constraint, "custom.") || contains(local.dry_run_constraints, policy.constraint)
  ) }
}

resource "google_org_policy_policy" "this" {
  for_each = local.policies

  name   = "${each.value.parent}/policies/${each.value.constraint}"
  parent = each.value.parent

  dynamic "spec" {
    for_each = var.mode == "enforced" ? [each.value] : []

    content {
      inherit_from_parent = spec.value.inherit_from_parent ? true : null

      rules {
        enforce    = spec.value.enforce == null ? null : (spec.value.enforce ? "TRUE" : "FALSE")
        parameters = spec.value.parameters
        allow_all  = spec.value.allow_all ? "TRUE" : null
        deny_all   = spec.value.deny_all ? "TRUE" : null

        dynamic "values" {
          for_each = length(spec.value.allow) + length(spec.value.deny) > 0 ? [spec.value] : []

          content {
            allowed_values = length(values.value.allow) > 0 ? values.value.allow : null
            denied_values  = length(values.value.deny) > 0 ? values.value.deny : null
          }
        }
      }
    }
  }

  dynamic "dry_run_spec" {
    for_each = var.mode == "dry_run" ? [each.value] : []

    content {
      inherit_from_parent = dry_run_spec.value.inherit_from_parent ? true : null

      rules {
        enforce    = dry_run_spec.value.enforce == null ? null : (dry_run_spec.value.enforce ? "TRUE" : "FALSE")
        parameters = dry_run_spec.value.parameters
        allow_all  = dry_run_spec.value.allow_all ? "TRUE" : null
        deny_all   = dry_run_spec.value.deny_all ? "TRUE" : null

        dynamic "values" {
          for_each = length(dry_run_spec.value.allow) + length(dry_run_spec.value.deny) > 0 ? [dry_run_spec.value] : []

          content {
            allowed_values = length(values.value.allow) > 0 ? values.value.allow : null
            denied_values  = length(values.value.deny) > 0 ? values.value.deny : null
          }
        }
      }
    }
  }
}
