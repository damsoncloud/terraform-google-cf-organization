terraform {
  required_version = ">= 1.15"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.11, < 9"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9, < 4"
    }
  }
}
