variable "organization_id" {
  description = "ID of the organisation, whose IAM policy is set authoritatively."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "The organization_id must be the numeric organisation ID."
  }
}

variable "domain" {
  description = "Domain of the organisation's groups, e.g. `example.com` for `gcp-organization-admins@example.com`."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.domain))
    error_message = "The domain must be a lowercase domain name, e.g. `example.com`."
  }
}

variable "environment_tag_key" {
  description = "Namespaced name of the `environment` tag key (`<organization_id>/environment`), e.g. the `environment_tag_key_namespaced_name` output of cf-hierarchy. The groups granted roles on a folder see it through the Folder Viewer role on the organisation, limited to the folder's tag value."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+/[^/]+$", var.environment_tag_key))
    error_message = "The environment_tag_key must be the namespaced name `<organization_id>/<short name>`."
  }
}

variable "folders" {
  description = "The folders by folder name, e.g. the `folders` output of cf-hierarchy, each tagged with its name as the `environment` tag value: `id`, the resource name (`folders/<id>`); `short_name`, the environment's short name, null for folders other than environments; `common`, whether it is the common environment. Each folder's IAM policy is set authoritatively, and each environment folder gets the `gcp-<short name>-<suffix>` groups of `environment_group_roles`. The foundations' projects are created in the common environment's folder and their generated IDs start with its short name."
  type = map(object({
    id         = string
    short_name = optional(string)
    common     = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for folder in values(var.folders) : can(regex("^folders/[0-9]+$", folder.id))])
    error_message = "Each folder's id must be `folders/<id>`."
  }

  validation {
    condition     = length([for folder in values(var.folders) : folder if folder.common && folder.short_name != null]) == 1 && length([for folder in values(var.folders) : folder if folder.common]) == 1
    error_message = "Exactly one folder must be the common environment, with a short name."
  }

  validation {
    condition     = length(distinct(compact([for folder in values(var.folders) : folder.short_name]))) == length(compact([for folder in values(var.folders) : folder.short_name]))
    error_message = "The short names must be unique."
  }
}

variable "billing_account" {
  description = "ID of the billing account of the foundations' projects and their budgets, e.g. `012345-6789AB-CDEF01`."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account))
    error_message = "The billing_account must be a billing account ID, e.g. `012345-6789AB-CDEF01`."
  }
}

variable "billing_admins_group_name" {
  description = "Name of the group administering the billing account, without the domain, notified of the budgets' alerts."
  type        = string
  default     = "gcp-billing-admins"
  nullable    = false
}

variable "bootstrap_project_id" {
  description = "ID of the bootstrap project, e.g. the `project_id` output of cf-bootstrap, which gets a budget."
  type        = string
}

variable "observability_project_id" {
  description = "ID of the Observability project. Generated as `<common short name>-observability-<suffix>`, e.g. `cmn-observability-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project."
  type        = string
  default     = null

  validation {
    condition     = var.observability_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.observability_project_id))
    error_message = "The observability_project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "api_management_project_id" {
  description = "ID of the API Management Hub project. Generated as `<common short name>-api-management-hub-<suffix>`, e.g. `cmn-api-management-hub-<suffix>`, with the suffix of a generated Observability project ID, when null; set it to keep the ID of an existing project."
  type        = string
  default     = null

  validation {
    condition     = var.api_management_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.api_management_project_id))
    error_message = "The api_management_project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "budget_amounts" {
  description = "Budget amounts of the foundations' projects, in the billing account's currency, alerting at 50%, 70% and 100%."
  type = object({
    bootstrap      = optional(number, 100)
    observability  = optional(number, 100)
    api_management = optional(number, 100)
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for amount in values(var.budget_amounts) : amount > 0 && floor(amount) == amount])
    error_message = "Each budget amount must be a positive whole number."
  }
}

variable "tf_bootstrap_email" {
  description = "Email of the `tf-bootstrap` service account, e.g. the `tf_bootstrap_email` output of cf-bootstrap."
  type        = string
}

variable "tf_bootstrap_organization_roles" {
  description = "Organisation roles of `tf-bootstrap`, e.g. the `tf_bootstrap_organization_roles` output of cf-bootstrap."
  type        = list(string)
}

variable "tf_plan_email" {
  description = "Email of the `tf-plan` service account, e.g. the `tf_plan_email` output of cf-bootstrap."
  type        = string
}

variable "tf_plan_organization_roles" {
  description = "Organisation roles of `tf-plan`, e.g. the `tf_plan_organization_roles` output of cf-bootstrap."
  type        = list(string)
}

variable "tf_environment_emails" {
  description = "Emails of the environment deployer service accounts by environment folder name, e.g. the `tf_environment_emails` output of cf-bootstrap. Each gets `environment_deployer_roles` on its folder."
  type        = map(string)

  validation {
    condition     = alltrue([for environment in keys(var.tf_environment_emails) : contains(keys(var.folders), environment)])
    error_message = "Each environment deployer must belong to one of the folders."
  }
}

variable "environment_deployer_roles" {
  description = "Roles of each environment deployer service account on its environment folder."
  type        = list(string)
  default = [
    "roles/resourcemanager.projectIamAdmin",
    "roles/writer",
  ]
  nullable = false
}

variable "organization_group_roles" {
  description = "Organisation roles by group name, without the domain."
  type        = map(list(string))
  default = {
    gcp-organization-admins = [
      "roles/billing.user",
      "roles/resourcemanager.organizationAdmin",
      "roles/resourcemanager.projectCreator",
    ]
    gcp-billing-admins = [
      "roles/billing.admin",
      "roles/billing.creator",
    ]
  }
  nullable = false
}

variable "environment_group_roles" {
  description = "Roles of each environment folder's groups by group name suffix; e.g. `sres` grants the roles to `gcp-dev-sres` on the `development` folder."
  type        = map(list(string))
  default = {
    sres    = ["roles/iam.siteReliabilityEngineer"]
    viewers = ["roles/reader"]
  }
  nullable = false
}

variable "folder_group_roles" {
  description = "Further roles of groups on folders, by folder name and group name without the domain."
  type        = map(map(list(string)))
  default = {
    development = {
      gcp-dev-developers = [
        "roles/iam.databasesAdmin",
        "roles/iam.devOps",
        "roles/iam.infrastructureAdmin",
      ]
    }
  }
  nullable = false

  validation {
    condition     = alltrue([for folder in keys(var.folder_group_roles) : contains(keys(var.folders), folder)])
    error_message = "Each folder of folder_group_roles must be one of the folders."
  }
}

variable "legacy_admins_group_name" {
  description = "Name of the group administering the `legacy` folder, without the domain."
  type        = string
  default     = "gcp-legacy-admins"
  nullable    = false
}

variable "legacy_admins_roles" {
  description = "Roles of the legacy administrators group on the `legacy` folder, if it is one of the folders."
  type        = list(string)
  default = [
    "roles/admin",
  ]
  nullable = false
}

variable "additional_organization_bindings" {
  description = "Further organisation members by role, e.g. `serviceAccount:` or `group:` members, and the Google-managed service agents granted at the organisation level, which the authoritative policy would remove otherwise."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "additional_folder_bindings" {
  description = "Further folder members by folder name and role."
  type        = map(map(list(string)))
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for folder in keys(var.additional_folder_bindings) : contains(keys(var.folders), folder)])
    error_message = "Each folder of additional_folder_bindings must be one of the folders."
  }
}

variable "audit_log_types" {
  description = "Data Access audit log types enabled for all services in the organisation; none when empty. Admin Activity audit logs are always written."
  type        = list(string)
  default     = ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]
  nullable    = false

  validation {
    condition     = alltrue([for log_type in var.audit_log_types : contains(["ADMIN_READ", "DATA_READ", "DATA_WRITE"], log_type)])
    error_message = "Each audit log type must be ADMIN_READ, DATA_READ or DATA_WRITE."
  }
}
