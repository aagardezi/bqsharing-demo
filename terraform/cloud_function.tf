# Source Bucket for Cloud Function
resource "google_storage_bucket" "cf_source_bucket" {
  project                     = var.provider_project_id
  name                        = "${var.provider_project_id}-cf-sources"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Zip the Cloud Function Source
data "archive_file" "cf_source" {
  type        = "zip"
  source_dir  = "${path.module}/../provider/cloud_function"
  output_path = "${path.module}/cf_source.zip"
}

# Upload Source Zip
resource "google_storage_bucket_object" "cf_source_archive" {
  name   = "cloud_function_source_${data.archive_file.cf_source.output_md5}.zip"
  bucket = google_storage_bucket.cf_source_bucket.name
  source = data.archive_file.cf_source.output_path
}

# Service Account for Cloud Function
resource "google_service_account" "cf_sa" {
  project      = var.provider_project_id
  account_id   = "bq-updater-cf-sa"
  display_name = "BigQuery Shared Views Updater Cloud Function SA"
}

# Grant CF SA permissions on BigQuery
resource "google_bigquery_dataset_iam_member" "cf_views_editor" {
  project    = var.provider_project_id
  dataset_id = google_bigquery_dataset.views_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.cf_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "cf_raw_viewer" {
  project    = var.provider_project_id
  dataset_id = google_bigquery_dataset.raw_dataset.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.cf_sa.email}"
}

# Log Writer permission for logs
resource "google_project_iam_member" "cf_log_writer" {
  project = var.provider_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# Pub/Sub Identity for Token Creation (needed for Eventarc)
resource "google_project_service_identity" "pubsub_agent" {
  provider = google-beta
  project  = var.provider_project_id
  service  = "pubsub.googleapis.com"
}

resource "google_project_iam_member" "pubsub_token_creator" {
  project = var.provider_project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_project_service_identity.pubsub_agent.email}"
}

# Eventarc Service Identity for invoking Cloud Run
resource "google_project_service_identity" "eventarc_agent" {
  provider = google-beta
  project  = var.provider_project_id
  service  = "eventarc.googleapis.com"
}

# Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "updater_function" {
  project     = var.provider_project_id
  name        = "bq-tick-views-updater"
  location    = var.region
  description = "Updates customer views SQL query when requested instrument list changes"

  build_config {
    runtime     = "python311"
    entry_point = "update_views"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_source_bucket.name
        object = google_storage_bucket_object.cf_source_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 3
    available_memory   = "256Mi"
    timeout_seconds    = 60
    service_account_email = google_service_account.cf_sa.email

    environment_variables = {
      PROVIDER_PROJECT_ID = var.provider_project_id
      RAW_DATASET_ID      = google_bigquery_dataset.raw_dataset.dataset_id
      VIEWS_DATASET_ID    = google_bigquery_dataset.views_dataset.dataset_id
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.instrument_requests.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_project_iam_member.pubsub_token_creator
  ]
}

# Grant Eventarc invoker permissions on the underlying Cloud Run service
resource "google_cloud_run_service_iam_member" "eventarc_invoker" {
  project  = var.provider_project_id
  location = google_cloudfunctions2_function.updater_function.location
  service  = google_cloudfunctions2_function.updater_function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_project_service_identity.eventarc_agent.email}"
}
