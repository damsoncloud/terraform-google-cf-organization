variable "project_id" {
  description = "ID of the Apps Script project."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "folder_id" {
  description = "The folder of the project (`folders/<id>`), e.g. the common environment's."
  type        = string
}

variable "billing_account" {
  description = "ID of the billing account of the project."
  type        = string
}

variable "apis" {
  description = "APIs enabled in the project, used by the Apps Scripts."
  type        = list(string)
}
