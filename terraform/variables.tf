variable "provider_project_id" {
  type         = string
  description = "The GCP project ID of the data provider"
  default     = "genaillentsearch"
}

variable "client_user_email" {
  type        = string
  description = "The Google Account email of the client subscriber/publisher"
  default     = "client-user@example.com"
}

variable "provider_developer_email" {
  type        = string
  description = "The Google Account email of the provider developer for local testing"
  default     = "provider-admin@example.com"
}

variable "region" {
  type        = string
  description = "The region to provision resources in"
  default     = "us-central1"
}
