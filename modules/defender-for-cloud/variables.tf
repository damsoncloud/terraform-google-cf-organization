variable "organization_id" {
  description = "ID of the organisation, where the custom roles are created."
  type        = string
}

variable "project_id" {
  description = "ID of the project of the service accounts, e.g. the Observability project, where cf-observability sets up their Workload Identity Federation from Azure."
  type        = string
}
