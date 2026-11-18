variable "folder_id" {
  description = "The `common` folder holding the foundations' projects, as `folders/<id>`, e.g. the `folders[\"common\"]` output of cf-hierarchy."
  type        = string

  validation {
    condition     = can(regex("^folders/[0-9]+$", var.folder_id))
    error_message = "The folder_id must be `folders/<id>`."
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

variable "billing_admins_group" {
  description = "Email of the group administering the billing account, e.g. `gcp-billing-admins@example.com`, notified of the budgets' alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.billing_admins_group))
    error_message = "The billing_admins_group must be an email address."
  }
}

variable "bootstrap_project_id" {
  description = "ID of the bootstrap project, e.g. the `project_id` output of cf-bootstrap, which gets a budget."
  type        = string
}

variable "observability_project_id" {
  description = "ID of the Observability project. Generated as `cmn-observability-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project."
  type        = string
  default     = null

  validation {
    condition     = var.observability_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.observability_project_id))
    error_message = "The observability_project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "api_management_project_id" {
  description = "ID of the API Management Hub project. Generated as `cmn-api-management-hub-<suffix>`, with the suffix of a generated Observability project ID, when null; set it to keep the ID of an existing project."
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
