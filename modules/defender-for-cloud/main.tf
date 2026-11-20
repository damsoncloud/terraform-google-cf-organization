locals {
  # The service accounts, their organisation custom roles and further organisation roles, named as Microsoft's onboarding expects
  service_accounts = {
    mdc-onboarding-sa = {
      custom_role = {
        name = "MicrosoftDefenderForCloudOnboardingCustomRole"
        permissions = [
          "compute.projects.get",
          "compute.projects.setCommonInstanceMetadata",
          "iam.roles.list",
          "resourcemanager.folders.get",
          "resourcemanager.folders.list",
          "resourcemanager.projects.get",
          "resourcemanager.projects.list",
          "serviceusage.services.enable",
        ]
      }
      org_level_roles_membership = []
    }
    microsoft-defender-cspm = {
      custom_role = {
        name = "MicrosoftDefenderForCloudCspmCustomRole"
        permissions = [
          "aiplatform.batchPredictionJobs.list",
          "aiplatform.datasets.list",
          "aiplatform.endpoints.list",
          "aiplatform.indexEndpoints.list",
          "aiplatform.indexes.list",
          "aiplatform.models.get",
          "aiplatform.models.list",
          "alloydb.backups.list",
          "alloydb.clusters.list",
          "alloydb.databases.list",
          "alloydb.instances.list",
          "alloydb.users.list",
          "apikeys.keys.list",
          "bigquery.datasets.get",
          "bigquery.tables.get",
          "bigquery.tables.getIamPolicy",
          "bigquery.tables.list",
          "certificatemanager.certs.list",
          "cloudasset.assets.analyzeIamPolicy",
          "cloudasset.assets.searchAllIamPolicies",
          "cloudasset.assets.searchAllResources",
          "cloudfunctions.functions.list",
          "cloudkms.cryptoKeys.getIamPolicy",
          "cloudkms.cryptoKeys.list",
          "cloudkms.keyRings.getIamPolicy",
          "cloudkms.keyRings.list",
          "cloudsql.instances.list",
          "compute.backendServices.list",
          "compute.disks.list",
          "compute.firewalls.list",
          "compute.forwardingRules.list",
          "compute.globalForwardingRules.list",
          "compute.images.list",
          "compute.instanceGroupManagers.get",
          "compute.instanceGroupManagers.list",
          "compute.instanceGroups.get",
          "compute.instanceGroups.list",
          "compute.instanceTemplates.list",
          "compute.instances.getEffectiveFirewalls",
          "compute.instances.list",
          "compute.machineTypes.list",
          "compute.networks.getEffectiveFirewalls",
          "compute.networks.list",
          "compute.projects.get",
          "compute.regionBackendServices.list",
          "compute.regionTargetHttpProxies.list",
          "compute.regionTargetHttpsProxies.list",
          "compute.regionUrlMaps.list",
          "compute.regions.list",
          "compute.sslPolicies.list",
          "compute.subnetworks.list",
          "compute.targetHttpProxies.list",
          "compute.targetHttpsProxies.list",
          "compute.targetPools.list",
          "compute.targetSslProxies.list",
          "compute.targetTcpProxies.list",
          "compute.urlMaps.list",
          "compute.vpnGateways.list",
          "compute.zones.list",
          "container.clusters.list",
          "datapipelines.pipelines.list",
          "dataproc.autoscalingPolicies.list",
          "dataproc.clusters.list",
          "dataproc.workflowTemplates.list",
          "datastore.databases.list",
          "datastream.connectionProfiles.list",
          "datastream.privateConnections.list",
          "datastream.streams.list",
          "dns.managedZones.list",
          "dns.policies.list",
          "file.backups.list",
          "file.instances.list",
          "iam.denypolicies.get",
          "iam.denypolicies.list",
          "iam.googleapis.com/workloadIdentityPoolProviders.get",
          "iam.googleapis.com/workloadIdentityPoolProviders.list",
          "iam.googleapis.com/workloadIdentityPools.get",
          "iam.googleapis.com/workloadIdentityPools.list",
          "iam.roles.get",
          "iam.roles.list",
          "iam.serviceAccountKeys.get",
          "iam.serviceAccountKeys.list",
          "iam.serviceAccounts.getIamPolicy",
          "iam.serviceAccounts.list",
          "logging.logEntries.list",
          "logging.logMetrics.list",
          "logging.sinks.list",
          "memcache.instances.list",
          "monitoring.alertPolicies.list",
          "notebooks.instances.list",
          "orgpolicy.policy.get",
          "osconfig.osPolicyAssignmentReports.list",
          "osconfig.osPolicyAssignments.list",
          "pubsub.subscriptions.getIamPolicy",
          "pubsub.subscriptions.list",
          "pubsub.topics.getIamPolicy",
          "pubsub.topics.list",
          "redis.clusters.list",
          "redis.instances.list",
          "resourcemanager.folders.getIamPolicy",
          "resourcemanager.folders.list",
          "resourcemanager.organizations.get",
          "resourcemanager.organizations.getIamPolicy",
          "resourcemanager.projects.get",
          "resourcemanager.projects.getIamPolicy",
          "resourcemanager.projects.list",
          "run.services.list",
          "secretmanager.secrets.getIamPolicy",
          "secretmanager.secrets.list",
          "spanner.databases.list",
          "spanner.instances.list",
          "storage.buckets.getIamPolicy",
          "storage.buckets.list",
        ]
      }
      org_level_roles_membership = ["roles/reader"]
    }
    mdc-containers-k8s-operator = {
      custom_role = {
        name = "MicrosoftDefenderForCloudContainersOperatorCustomRole"
        permissions = [
          # keep-sorted start
          "container.clusters.update",
          "container.networkPolicies.create",
          "container.networkPolicies.delete",
          "container.networkPolicies.update",
          "container.nodes.proxy",
          "container.pods.delete",
          "container.pods.update",
          "container.secrets.list",
          # keep-sorted end
        ]
      }
      org_level_roles_membership = ["roles/container.viewer"]
    }
    mdc-containers-artifact-assess = {
      custom_role = {
        name = "MicrosoftDefenderForCloudContainersAssessmentCustomRole"
        permissions = [
          "artifactregistry.repositories.deleteArtifacts",
          "artifactregistry.repositories.uploadArtifacts",
        ]
      }
      org_level_roles_membership = [
        "roles/artifactregistry.reader",
        "roles/storage.objectViewer",
      ]
    }
    microsoft-defender-containers = {
      custom_role = {
        name = "MicrosoftDefenderForCloudContainersCustomRole"
        permissions = [
          "iam.serviceAccounts.get",
          "iam.workloadIdentityPoolProviders.get",
          "logging.sinks.create",
          "logging.sinks.delete",
          "logging.sinks.get",
          "logging.sinks.list",
          "logging.sinks.update",
          "resourcemanager.organizations.getIamPolicy",
          "resourcemanager.projects.getIamPolicy",
        ]
      }
      org_level_roles_membership = [
        "roles/container.admin",
        "roles/pubsub.admin",
      ]
    }
    ms-defender-containers-stream = {
      custom_role = {
        name = "MicrosoftDefenderForCloudContainersDataCollectionCustomRole"
        permissions = [
          "pubsub.subscriptions.consume",
          "pubsub.subscriptions.get",
        ]
      }
      org_level_roles_membership = []
    }
    microsoft-defender-for-servers = {
      org_level_roles_membership = [
        "roles/compute.viewer",
        "roles/osconfig.osPolicyAssignmentAdmin",
        "roles/osconfig.osPolicyAssignmentReportViewer",
      ]
    }
    microsoft-databases-arc-ap = {
      org_level_roles_membership = [
        "roles/compute.viewer",
        "roles/osconfig.osPolicyAssignmentAdmin",
        "roles/osconfig.osPolicyAssignmentReportViewer",
      ]
    }
    mdc-data-sec-posture-storage = {
      custom_role = {
        name = "MicrosoftDefenderForCloudSecurityPostureStorageCustomRole"
        permissions = [
          "storage.buckets.get",
          "storage.objects.get",
          "storage.objects.list",
        ]
      }
      org_level_roles_membership = []
    }
    mdc-ciem-gcp = {
      custom_role = {
        name = "MicrosoftDefenderForCloudLoggingHydrationCustomRole"
        permissions = [
          "logging.buckets.copyLogEntries",
          "logging.logEntries.list",
        ]
      }
      org_level_roles_membership = []
    }
    mdc-log-collection = {
      custom_role = {
        name = "MicrosoftDefenderForCloudLogCollectionCustomRole"
        permissions = [
          "pubsub.subscriptions.consume",
          "pubsub.subscriptions.get",
        ]
      }
      org_level_roles_membership = []
    }
  }

  # Microsoft's identities scanning the disks of the instances, the second one decrypting the CMEK-encrypted disks
  agentless_scanning_member = "serviceAccount:mdc-agentless-scanning@guardians-prod-diskscanning.iam.gserviceaccount.com"
  disk_decryption_member    = "serviceAccount:service-220551266886@compute-system.iam.gserviceaccount.com"
}

resource "google_organization_iam_custom_role" "defender_for_cloud" {
  for_each = { for name, account in local.service_accounts : name => account.custom_role if try(account.custom_role, null) != null }

  org_id      = var.organization_id
  role_id     = each.value.name
  title       = each.value.name
  description = "Microsoft Defender for Cloud integration - ${each.key}"
  permissions = each.value.permissions
}

resource "google_organization_iam_custom_role" "agentless_scanning" {
  org_id      = var.organization_id
  role_id     = "MicrosoftDefenderForCloudAgentlessScanningCustomRole"
  title       = "MicrosoftDefenderForCloudAgentlessScanningCustomRole"
  description = "Microsoft Defender for Cloud integration - agentless scanning"
  permissions = [
    "compute.disks.createSnapshot",
    "compute.instances.get",
  ]
}

resource "google_service_account" "defender_for_cloud" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = "Microsoft Defender for Cloud - ${each.key}"
}
