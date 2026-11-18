# Tests of the modules/org-policies submodule, called directly
mock_provider "google" {}

variables {
  organization_id = "123456789012"
  mode            = "enforced"
}

run "enforced_baseline" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  assert {
    condition = keys(google_org_policy_policy.this) == [for constraint in [
      "compute.managed.blockPreviewFeatures",
      "compute.managed.blockProjectSshKeys",
      "compute.managed.disableSerialPortAccess",
      "compute.managed.vmExternalIpAccess",
      "compute.restrictVpcPeering",
      "compute.skipDefaultNetworkCreation",
      "dataflow.managed.disableUsePublicIps",
      "gcp.resourceLocations",
      "gcp.restrictServiceUsage",
      "iam.managed.allowedPolicyMembers",
      "iam.managed.disableServiceAccountApiKeyCreation",
      "iam.managed.disableServiceAccountKeyCreation",
      "iam.managed.disableServiceAccountKeyUpload",
      "iam.managed.preventPrivilegedBasicRolesForDefaultServiceAccounts",
      "spanner.managed.restrictCloudSpannerEditions",
      "storage.uniformBucketLevelAccess",
    ] : "organizations/123456789012/${constraint}"]
    error_message = "The baseline must set all its policies on the organisation."
  }

  assert {
    condition = alltrue([for key, policy in google_org_policy_policy.this :
      policy.name == "organizations/123456789012/policies/${element(split("/", key), 2)}" && length(policy.spec) == 1 && length(policy.dry_run_spec) == 0
    ])
    error_message = "Each policy must be enforced, without a dry-run policy."
  }

  assert {
    condition = alltrue([for constraint in ["compute.managed.vmExternalIpAccess", "compute.skipDefaultNetworkCreation", "storage.uniformBucketLevelAccess"] :
      google_org_policy_policy.this["organizations/123456789012/${constraint}"].spec[0].rules[0].enforce == "TRUE"
    ])
    error_message = "The boolean constraints must be enforced."
  }

  assert {
    condition = (
      google_org_policy_policy.this["organizations/123456789012/gcp.resourceLocations"].spec[0].rules[0].values[0].allowed_values == tolist(["in:europe-west4-locations"]) &&
      google_org_policy_policy.this["organizations/123456789012/compute.restrictVpcPeering"].spec[0].rules[0].deny_all == "TRUE" &&
      contains(google_org_policy_policy.this["organizations/123456789012/gcp.restrictServiceUsage"].spec[0].rules[0].values[0].allowed_values, "run.googleapis.com") &&
      !contains(google_org_policy_policy.this["organizations/123456789012/gcp.restrictServiceUsage"].spec[0].rules[0].values[0].allowed_values, "generativelanguage.googleapis.com")
    )
    error_message = "The list constraints must allow the default locations and services, without the Gemini API, and deny VPC peering."
  }

  assert {
    condition = jsondecode(google_org_policy_policy.this["organizations/123456789012/spanner.managed.restrictCloudSpannerEditions"].spec[0].rules[0].parameters) == {
      deniedEditions = ["ENTERPRISE", "ENTERPRISE_PLUS"]
    }
    error_message = "The Enterprise editions of Spanner must be denied."
  }

  assert {
    condition = jsondecode(google_org_policy_policy.this["organizations/123456789012/iam.managed.allowedPolicyMembers"].spec[0].rules[0].parameters) == {
      allowedMemberSubjects = ["serviceAccount:billing-budget-alert@system.gserviceaccount.com"]
      allowedPrincipalSets  = ["//cloudresourcemanager.googleapis.com/organizations/123456789012"]
    }
    error_message = "Only the organisation's principal set and Cloud Billing's account must be allowed in IAM allow policies."
  }
}

run "dry_run" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    mode             = "dry_run"
    legacy_folder_id = "folders/100000000004"
  }

  assert {
    condition = alltrue([for constraint in ["gcp.resourceLocations", "compute.restrictVpcPeering", "compute.skipDefaultNetworkCreation", "storage.uniformBucketLevelAccess"] :
      !contains(keys(google_org_policy_policy.this), "organizations/123456789012/${constraint}")
    ])
    error_message = "The policies whose constraints do not support dry-run must not be set in dry-run mode."
  }

  assert {
    condition = length(google_org_policy_policy.this) == 14 && alltrue([for policy in google_org_policy_policy.this :
      length(policy.spec) == 0 && length(policy.dry_run_spec) == 1
    ])
    error_message = "The managed constraints, gcp.restrictServiceUsage and the legacy folder's exceptions must be set as dry-run policies only."
  }
}

run "exceptions" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    legacy_folder_id = "folders/100000000004"
    api_management = {
      project_id = "cmn-api-management-hub-c3d4"
    }
    shared_vpc_host_folder_id = "folders/111111111111"
  }

  assert {
    condition = (
      google_org_policy_policy.this["folders/100000000004/gcp.restrictServiceUsage"].spec[0].rules[0].allow_all == "TRUE" &&
      google_org_policy_policy.this["folders/100000000004/iam.managed.disableServiceAccountKeyCreation"].spec[0].rules[0].enforce == "FALSE"
    )
    error_message = "The legacy folder must not restrict service usage and service account key creation."
  }

  assert {
    condition = (
      google_org_policy_policy.this["projects/cmn-api-management-hub-c3d4/gcp.restrictServiceUsage"].spec[0].inherit_from_parent &&
      google_org_policy_policy.this["projects/cmn-api-management-hub-c3d4/gcp.restrictServiceUsage"].spec[0].rules[0].values[0].allowed_values == tolist(["apikeys.googleapis.com", "generativelanguage.googleapis.com"])
    )
    error_message = "The API Management Hub project must also allow the API keys and Gemini APIs."
  }

  assert {
    condition     = google_org_policy_policy.this["organizations/123456789012/compute.restrictSharedVpcHostProjects"].spec[0].rules[0].values[0].allowed_values == tolist(["under:folders/111111111111"])
    error_message = "Shared VPC host projects must be restricted to the given folder."
  }
}

run "customisations" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    allowed_locations                 = ["in:europe-west4-locations", "in:europe-west1-locations"]
    additional_allowed_services       = ["dns.googleapis.com"]
    additional_allowed_members        = ["user:someone@partner.example"]
    additional_allowed_principal_sets = ["//cloudresourcemanager.googleapis.com/organizations/999999999999"]
    allowed_vpc_peering_networks      = ["under:organizations/123456789012"]
    disabled_constraints              = ["compute.managed.vmExternalIpAccess"]
    additional_policies = [
      {
        constraint = "compute.managed.blockPreviewFeatures"
        enforce    = true
        parameters = jsonencode({ allowedPreviewFeatures = ["someFeature"] })
      },
      {
        constraint = "storage.uniformBucketLevelAccess"
        parent     = "projects/dc-dev-example-1234"
        enforce    = false
      },
    ]
  }

  assert {
    condition = (
      !contains(keys(google_org_policy_policy.this), "organizations/123456789012/compute.managed.vmExternalIpAccess") &&
      jsondecode(google_org_policy_policy.this["organizations/123456789012/compute.managed.blockPreviewFeatures"].spec[0].rules[0].parameters) == { allowedPreviewFeatures = ["someFeature"] } &&
      google_org_policy_policy.this["projects/dc-dev-example-1234/storage.uniformBucketLevelAccess"].spec[0].rules[0].enforce == "FALSE"
    )
    error_message = "Disabled constraints must not be set, and additional policies must replace the baseline's or be added."
  }

  assert {
    condition = (
      length(google_org_policy_policy.this["organizations/123456789012/gcp.resourceLocations"].spec[0].rules[0].values[0].allowed_values) == 2 &&
      contains(google_org_policy_policy.this["organizations/123456789012/gcp.restrictServiceUsage"].spec[0].rules[0].values[0].allowed_values, "dns.googleapis.com") &&
      google_org_policy_policy.this["organizations/123456789012/compute.restrictVpcPeering"].spec[0].rules[0].values[0].allowed_values == tolist(["under:organizations/123456789012"]) &&
      google_org_policy_policy.this["organizations/123456789012/compute.restrictVpcPeering"].spec[0].rules[0].deny_all == null
    )
    error_message = "The locations, services and VPC peering networks must follow the inputs."
  }

  assert {
    condition = jsondecode(google_org_policy_policy.this["organizations/123456789012/iam.managed.allowedPolicyMembers"].spec[0].rules[0].parameters) == {
      allowedMemberSubjects = ["serviceAccount:billing-budget-alert@system.gserviceaccount.com", "user:someone@partner.example"]
      allowedPrincipalSets  = ["//cloudresourcemanager.googleapis.com/organizations/123456789012", "//cloudresourcemanager.googleapis.com/organizations/999999999999"]
    }
    error_message = "The additional members and principal sets must be allowed."
  }
}

run "invalid_mode" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    mode = "enforce"
  }

  expect_failures = [var.mode]
}

run "invalid_legacy_folder_id" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    legacy_folder_id = "100000000004"
  }

  expect_failures = [var.legacy_folder_id]
}

run "invalid_additional_allowed_member" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    additional_allowed_members = ["someone@partner.example"]
  }

  expect_failures = [var.additional_allowed_members]
}

run "invalid_additional_allowed_principal_set" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    additional_allowed_principal_sets = ["organizations/999999999999"]
  }

  expect_failures = [var.additional_allowed_principal_sets]
}

run "invalid_additional_policy_parent" {
  command = plan

  module {
    source = "./modules/org-policies"
  }

  variables {
    additional_policies = [{ constraint = "storage.uniformBucketLevelAccess", parent = "dc-dev-example-1234" }]
  }

  expect_failures = [var.additional_policies]
}
