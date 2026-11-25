locals {
  access_policy_id = var.access_policy_id != null ? var.access_policy_id : google_access_context_manager_access_policy.organization[0].name
  access_policy    = "accessPolicies/${local.access_policy_id}"
  perimeter        = "${local.access_policy}/servicePerimeters/${var.perimeter_name}"

  restricted_services = distinct(concat(var.restricted_services, var.additional_restricted_services))
  enforced            = var.mode == "enforced"

  ingress_policies = { for policy in concat(
    length(var.deployers) == 0 ? [] : [{
      title                = "Deployers"
      identities           = [for email in var.deployers : "serviceAccount:${email}"]
      identity_type        = null
      source_access_levels = ["*"]
      source_resources     = []
      resources            = ["*"]
      operations           = { "*" = [] }
    }],
    length(var.groups) == 0 ? [] : [{
      title                = "Foundations' groups"
      identities           = [for email in var.groups : "group:${email}"]
      identity_type        = null
      source_access_levels = ["*"]
      source_resources     = []
      resources            = ["*"]
      operations           = { "*" = [] }
    }],
    # Budget notifications published to the billing disabler's topic
    [{
      title                = "Cloud Billing budget notifications"
      identities           = ["serviceAccount:billing-budget-alert@system.gserviceaccount.com"]
      identity_type        = null
      source_access_levels = ["*"]
      source_resources     = []
      resources            = ["*"]
      operations           = { "pubsub.googleapis.com" = ["Publisher.Publish"] }
    }],
    [for policy in var.ingress_policies : merge(policy, {
      source_access_levels = [for level in policy.source_access_levels : contains(keys(var.access_levels), level) ? "${local.access_policy}/accessLevels/${level}" : level]
    })],
  ) : policy.title => policy }
}

resource "google_access_context_manager_access_policy" "organization" {
  count = var.access_policy_id == null ? 1 : 0

  parent = "organizations/${var.organization_id}"
  title  = "Organisation access policy"
}

resource "google_access_context_manager_access_level" "levels" {
  for_each = var.access_levels

  parent = local.access_policy
  name   = "${local.access_policy}/accessLevels/${each.key}"
  title  = each.key

  basic {
    conditions {
      ip_subnetworks = length(each.value.ip_subnetworks) > 0 ? each.value.ip_subnetworks : null
      members        = length(each.value.members) > 0 ? each.value.members : null
      regions        = length(each.value.regions) > 0 ? each.value.regions : null
    }
  }
}

resource "google_access_context_manager_service_perimeter" "foundations" {
  parent                    = local.access_policy
  name                      = local.perimeter
  title                     = "Cloud Foundations and production"
  perimeter_type            = "PERIMETER_TYPE_REGULAR"
  use_explicit_dry_run_spec = true

  # In dry-run mode, the enforced configuration holds the projects but restricts no service
  status {
    restricted_services = local.enforced ? local.restricted_services : []

    dynamic "egress_policies" {
      for_each = local.enforced ? var.egress_policies : []

      content {
        title = egress_policies.value.title

        egress_from {
          identities    = length(egress_policies.value.identities) > 0 ? egress_policies.value.identities : null
          identity_type = egress_policies.value.identity_type
        }

        egress_to {
          resources          = length(egress_policies.value.resources) > 0 ? egress_policies.value.resources : null
          external_resources = length(egress_policies.value.external_resources) > 0 ? egress_policies.value.external_resources : null

          dynamic "operations" {
            for_each = egress_policies.value.operations

            content {
              service_name = operations.key

              dynamic "method_selectors" {
                for_each = operations.key == "*" ? [] : (length(operations.value) > 0 ? operations.value : ["*"])

                content {
                  method = method_selectors.value
                }
              }
            }
          }
        }
      }
    }
  }

  # The dry-run configuration always holds the full restrictions, so that changes can be tested before they are enforced
  spec {
    restricted_services = local.restricted_services

    dynamic "egress_policies" {
      for_each = var.egress_policies

      content {
        title = egress_policies.value.title

        egress_from {
          identities    = length(egress_policies.value.identities) > 0 ? egress_policies.value.identities : null
          identity_type = egress_policies.value.identity_type
        }

        egress_to {
          resources          = length(egress_policies.value.resources) > 0 ? egress_policies.value.resources : null
          external_resources = length(egress_policies.value.external_resources) > 0 ? egress_policies.value.external_resources : null

          dynamic "operations" {
            for_each = egress_policies.value.operations

            content {
              service_name = operations.key

              dynamic "method_selectors" {
                for_each = operations.key == "*" ? [] : (length(operations.value) > 0 ? operations.value : ["*"])

                content {
                  method = method_selectors.value
                }
              }
            }
          }
        }
      }
    }
  }

  # The projects and ingress rules are added by their own resources, here and in the modules creating the projects and the flows
  lifecycle {
    ignore_changes = [status[0].resources, spec[0].resources, status[0].ingress_policies, spec[0].ingress_policies]
  }

  depends_on = [google_access_context_manager_access_level.levels]
}

# Each project is added to both configurations, so that switching the mode does not change the membership
resource "google_access_context_manager_service_perimeter_resource" "projects" {
  for_each = var.projects

  perimeter_name = google_access_context_manager_service_perimeter.foundations.name
  resource       = "projects/${each.value}"
}

resource "google_access_context_manager_service_perimeter_dry_run_resource" "projects" {
  for_each = var.projects

  perimeter_name = google_access_context_manager_service_perimeter.foundations.name
  resource       = "projects/${each.value}"
}

# Rules are added to the enforced configuration only when enforced, and always to the dry-run configuration, which holds the full restrictions
resource "google_access_context_manager_service_perimeter_ingress_policy" "rules" {
  for_each = local.enforced ? local.ingress_policies : {}

  title     = each.key
  perimeter = google_access_context_manager_service_perimeter.foundations.name

  ingress_from {
    identities    = length(each.value.identities) > 0 ? each.value.identities : null
    identity_type = each.value.identity_type

    dynamic "sources" {
      for_each = each.value.source_access_levels

      content {
        access_level = sources.value
      }
    }

    dynamic "sources" {
      for_each = each.value.source_resources

      content {
        resource = sources.value
      }
    }
  }

  ingress_to {
    resources = each.value.resources

    dynamic "operations" {
      for_each = each.value.operations

      content {
        service_name = operations.key

        dynamic "method_selectors" {
          for_each = operations.key == "*" ? [] : (length(operations.value) > 0 ? operations.value : ["*"])

          content {
            method = method_selectors.value
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_access_context_manager_access_level.levels]
}

resource "google_access_context_manager_service_perimeter_dry_run_ingress_policy" "rules" {
  for_each = local.ingress_policies

  title     = each.key
  perimeter = google_access_context_manager_service_perimeter.foundations.name

  ingress_from {
    identities    = length(each.value.identities) > 0 ? each.value.identities : null
    identity_type = each.value.identity_type

    dynamic "sources" {
      for_each = each.value.source_access_levels

      content {
        access_level = sources.value
      }
    }

    dynamic "sources" {
      for_each = each.value.source_resources

      content {
        resource = sources.value
      }
    }
  }

  ingress_to {
    resources = each.value.resources

    dynamic "operations" {
      for_each = each.value.operations

      content {
        service_name = operations.key

        dynamic "method_selectors" {
          for_each = operations.key == "*" ? [] : (length(operations.value) > 0 ? operations.value : ["*"])

          content {
            method = method_selectors.value
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_access_context_manager_access_level.levels]
}
