variable "organization_id" {
  description = "ID of the organisation, the parent of the access policy created when `access_policy_id` is null."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "The organization_id must be the numeric organisation ID."
  }
}

variable "mode" {
  description = "`dry_run` sets the restrictions and rules in the perimeter's dry-run configuration only, whose violations are recorded in the audit logs; `enforced` also enforces them."
  type        = string

  validation {
    condition     = contains(["dry_run", "enforced"], var.mode)
    error_message = "The mode must be dry_run or enforced."
  }
}

variable "access_policy_id" {
  description = <<-EOT
  ID of the organisation's existing access policy, of which there can be only one; the perimeter is added to it, and its other perimeters are left as they are.
  An access policy is created when null.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.access_policy_id == null || can(regex("^[0-9]+$", var.access_policy_id))
    error_message = "The access_policy_id must be the numeric access policy ID."
  }
}

variable "perimeter_name" {
  description = "Short name of the perimeter, unique in the access policy."
  type        = string
  default     = "cloud_foundations_production"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,49}$", var.perimeter_name))
    error_message = "The perimeter_name must be 1-50 letters, digits or underscores, starting with a letter."
  }
}

variable "projects" {
  description = <<-EOT
  Numbers of the projects in the perimeter, by a static key, e.g. the bootstrap and common projects;
  the modules creating the other projects add them with the `perimeter_name` output.
  EOT
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for number in values(var.projects) : can(regex("^[0-9]+$", number))])
    error_message = "Each project must be given by its number."
  }
}

variable "restricted_services" {
  description = <<-EOT
  Services restricted by the perimeter: by default, the generally available services supported by VPC Service Controls among the services allowed by the org-policies submodule
  and those used by the foundations.
  EOT
  type        = list(string)
  default = [
    "agentidentity.googleapis.com",
    "agentidentitycredentials.googleapis.com",
    "agentregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigtable.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudfunctions.googleapis.com",
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
    "datastream.googleapis.com",
    "dns.googleapis.com",
    "documentai.googleapis.com",
    "essentialcontacts.googleapis.com",
    "eventarc.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "iaptunnel.googleapis.com",
    "logging.googleapis.com",
    "memorystore.googleapis.com",
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com",
    "orgpolicy.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
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
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "spanner.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "storagebatchoperations.googleapis.com",
    "storageinsights.googleapis.com",
    "storagetransfer.googleapis.com",
    "sts.googleapis.com",
    "texttospeech.googleapis.com",
    "translate.googleapis.com",
    "vectorsearch.googleapis.com",
    "workflows.googleapis.com",
    "workloadidentity.googleapis.com",
  ]
  nullable = false
}

variable "additional_restricted_services" {
  description = "Services restricted by the perimeter in addition to `restricted_services`."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "deployers" {
  description = <<-EOT
  Emails of the service accounts deploying from outside the perimeter, e.g. GitHub-hosted runners, allowed to access the perimeter from any source:
  `tf-bootstrap`, `tf-plan` and the environment deployers of cf-bootstrap.
  EOT
  type        = list(string)
  default     = []
  nullable    = false
}

variable "groups" {
  description = <<-EOT
  Emails of the groups whose members access the perimeter's projects from outside it, from any source, e.g. the `perimeter_groups` output of cf-organization.
  For a stricter access, e.g. from the office network or managed devices only, leave it empty and use `access_levels` and `ingress_policies` instead.
  EOT
  type        = list(string)
  default     = []
  nullable    = false
}

variable "access_levels" {
  description = <<-EOT
  Basic access levels created in the access policy, by name, for the sources of `ingress_policies`:
    the requests' `ip_subnetworks`, `members` and `regions`, all of which must match.
  EOT
  type = map(object({
    ip_subnetworks = optional(list(string), [])
    members        = optional(list(string), [])
    regions        = optional(list(string), [])
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in keys(var.access_levels) : can(regex("^[A-Za-z][A-Za-z0-9_]{0,49}$", name))])
    error_message = "Each access level's name must be 1-50 letters, digits or underscores, starting with a letter."
  }
}

variable "ingress_policies" {
  description = <<-EOT
  Ingress rules in addition to the deployers', the foundations' groups' and Cloud Billing's, by their unique `title`:
    `identities` or `identity_type` (`ANY_IDENTITY`, `ANY_USER_ACCOUNT` or `ANY_SERVICE_ACCOUNT`), the principals allowed;
    `source_access_levels`, the names of `access_levels` or `*` for any source, and `source_resources`, e.g. `projects/<number>`;
    `resources`, the projects in the perimeter, `*` for all;
    `operations`, the methods by service, `*` for all services, and all methods of a service when its list is empty.
  EOT
  type = list(object({
    title                = string
    identities           = optional(list(string), [])
    identity_type        = optional(string)
    source_access_levels = optional(list(string), [])
    source_resources     = optional(list(string), [])
    resources            = optional(list(string), ["*"])
    operations           = optional(map(list(string)), { "*" = [] })
  }))
  default  = []
  nullable = false

  validation {
    condition = (
      length(distinct([for policy in var.ingress_policies : policy.title])) == length(var.ingress_policies) &&
      !anytrue([for policy in var.ingress_policies : contains(["Deployers", "Foundations' groups", "Cloud Billing budget notifications"], policy.title)])
    )
    error_message = "The ingress rules' titles must be unique, and differ from the deployers', the foundations' groups' and Cloud Billing's rules."
  }
}

variable "egress_policies" {
  description = <<-EOT
  Egress rules:
    `identities` or `identity_type`, the principals allowed;
    `resources`, the projects outside the perimeter, e.g. `projects/<number>`, `*` for all, and `external_resources`, e.g. Amazon S3 buckets;
    `operations`, the methods by service, as in `ingress_policies`.
  EOT
  type = list(object({
    title              = optional(string)
    identities         = optional(list(string), [])
    identity_type      = optional(string)
    resources          = optional(list(string), [])
    external_resources = optional(list(string), [])
    operations         = optional(map(list(string)), { "*" = [] })
  }))
  default  = []
  nullable = false
}
