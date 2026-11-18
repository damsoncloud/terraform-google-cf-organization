variable "organization_id" {
  description = "ID of the organisation, where the baseline policies are set."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "The organization_id must be the numeric organisation ID."
  }
}

variable "mode" {
  description = "`dry_run` sets only the policies whose constraints support dry-run, as dry-run policies; `enforced` enforces all policies."
  type        = string

  validation {
    condition     = contains(["dry_run", "enforced"], var.mode)
    error_message = "The mode must be dry_run or enforced."
  }
}

variable "allowed_locations" {
  description = "Values of the `gcp.resourceLocations` constraint: the locations where resources can be created, e.g. the primary and DR regions' value groups."
  type        = list(string)
  default     = ["in:europe-west4-locations"]
  nullable    = false

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "At least one location must be allowed."
  }
}

variable "allowed_services" {
  description = "Services allowed by the `gcp.restrictServiceUsage` constraint in the organisation. Services the constraint does not support are always allowed."
  type        = list(string)
  default = [
    # keep-sorted start
    "agentidentity.googleapis.com",
    "agentidentitycredentials.googleapis.com",
    "agentregistry.googleapis.com",
    "agentregistryendpoint.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerybiengine.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigqueryscripts.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigtable.googleapis.com",
    "bigtableadmin.googleapis.com",
    "bigtableclusteradmin.googleapis.com",
    "bigtabletableadmin.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudprofiler.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containersecurity.googleapis.com",
    "containerthreatdetection.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "datafusion.googleapis.com",
    "datastore.googleapis.com",
    "datastream.googleapis.com",
    "datastudio.googleapis.com",
    "documentai.googleapis.com",
    "eventarc.googleapis.com",
    "iap.googleapis.com",
    "identityplatform.googleapis.com",
    "memorystore.googleapis.com",
    "modelarmor.googleapis.com",
    "notebooks.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "policyanalyzer.googleapis.com",
    "policysimulator.googleapis.com",
    "privilegedaccessmanager.googleapis.com",
    "pubsub.googleapis.com",
    "pubsublite.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    "recommender.googleapis.com",
    "redis.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "securitycentermanagement.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicehealth.googleapis.com",
    "spanner.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "storagebatchoperations.googleapis.com",
    "storageinsights.googleapis.com",
    "storagetransfer.googleapis.com",
    "texttospeech.googleapis.com",
    "threatdetection.googleapis.com",
    "translate.googleapis.com",
    "vectorsearch.googleapis.com",
    "workflows.googleapis.com",
    "workloadidentity.googleapis.com",
    # keep-sorted end
  ]
  nullable = false
}

variable "additional_allowed_services" {
  description = "Services allowed by the `gcp.restrictServiceUsage` constraint in the organisation in addition to `allowed_services`."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "additional_allowed_members" {
  description = "Principals allowed in IAM allow policies by the `iam.managed.allowedPolicyMembers` constraint, e.g. `user:someone@partner.example`, in addition to the organisation's principal set and `billing-budget-alert@system.gserviceaccount.com`."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for member in var.additional_allowed_members : strcontains(member, ":")])
    error_message = "Each additional allowed member must be a principal identifier, `<type>:<id>`."
  }
}

variable "additional_allowed_principal_sets" {
  description = "Principal sets allowed in IAM allow policies by the `iam.managed.allowedPolicyMembers` constraint, e.g. another organisation's `//cloudresourcemanager.googleapis.com/organizations/<id>`, in addition to the organisation's."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for principal_set in var.additional_allowed_principal_sets : startswith(principal_set, "//")])
    error_message = "Each additional allowed principal set must be a principal set identifier starting with `//`."
  }
}

variable "allowed_vpc_peering_networks" {
  description = "Values of the `compute.restrictVpcPeering` constraint: the networks VPC networks may peer with, e.g. `under:organizations/<id>`; peering is denied when empty."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "legacy_folder_id" {
  description = "The `legacy` folder (`folders/<id>`), e.g. the `folders[\"legacy\"].id` output of cf-hierarchy, where service usage and service account key creation are not restricted; no exceptions when null."
  type        = string
  default     = null

  validation {
    condition     = var.legacy_folder_id == null || can(regex("^folders/[0-9]+$", var.legacy_folder_id))
    error_message = "The legacy_folder_id must be `folders/<id>`."
  }
}

variable "api_management" {
  description = "The API Management Hub project, e.g. the `api_management_project_id` output of cf-organization, and the services allowed there in addition to the organisation's, e.g. the Gemini API; no exception when null."
  type = object({
    project_id       = string
    allowed_services = optional(list(string), ["apikeys.googleapis.com", "generativelanguage.googleapis.com"])
  })
  default = null
}

variable "shared_vpc_host_folder_id" {
  description = "The folder (`folders/<id>`) where Shared VPC host projects can be, e.g. the common environment's folder, enforced with `compute.restrictSharedVpcHostProjects`; not restricted when null."
  type        = string
  default     = null

  validation {
    condition     = var.shared_vpc_host_folder_id == null || can(regex("^folders/[0-9]+$", var.shared_vpc_host_folder_id))
    error_message = "The shared_vpc_host_folder_id must be `folders/<id>`."
  }
}

variable "disabled_constraints" {
  description = "Constraints of the organisation-level baseline not to set, e.g. `compute.managed.vmExternalIpAccess`."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "additional_policies" {
  description = <<-EOT
    Further policies, replacing the baseline's policy of the same constraint on the same resource:
    `constraint`, the constraint's name, e.g. `custom.denyExternalBuckets`;
    `parent`, the resource, `organizations/<id>`, `folders/<id>` or `projects/<id>`, the organisation when null;
    `enforce`, for boolean constraints, managed constraints included;
    `parameters`, the parameters of a managed constraint, JSON-encoded, e.g. `jsonencode({ allowedPreviewFeatures = [] })`;
    `allow` and `deny`, the values of a list constraint, `allow_all` and `deny_all` to allow or deny all values;
    `inherit_from_parent`, whether a list policy is merged with its parent's.
  EOT
  type = list(object({
    constraint          = string
    parent              = optional(string)
    enforce             = optional(bool)
    parameters          = optional(string)
    allow               = optional(list(string), [])
    deny                = optional(list(string), [])
    allow_all           = optional(bool, false)
    deny_all            = optional(bool, false)
    inherit_from_parent = optional(bool, false)
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for policy in var.additional_policies : policy.parent == null || can(regex("^(organizations|folders|projects)/[^/]+$", policy.parent))])
    error_message = "Each additional policy's parent must be `organizations/<id>`, `folders/<id>` or `projects/<id>`."
  }

  validation {
    condition     = alltrue([for policy in var.additional_policies : policy.parameters == null || can(jsondecode(policy.parameters))])
    error_message = "Each additional policy's parameters must be JSON-encoded."
  }
}
