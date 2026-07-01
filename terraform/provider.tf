terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  region                = var.region
  user_project_override = true
  billing_project       = var.provider_project_id
}

provider "google-beta" {
  region                = var.region
  user_project_override = true
  billing_project       = var.provider_project_id
}
