variable "projects" {
  description = <<-EOT
  The Firebase projects by environment folder name:
    `project_id`;
    the folder (`folder_id`, `folders/<id>`).
  EOT
  type = map(object({
    project_id = string
    folder_id  = string
  }))

  validation {
    condition     = alltrue([for project in values(var.projects) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project.project_id))])
    error_message = "Each project_id must be 6-30 lowercase letters, digits or hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "billing_account" {
  description = "ID of the billing account of the projects."
  type        = string
}

variable "apis" {
  description = "Firebase APIs enabled in the projects."
  type        = list(string)
}
