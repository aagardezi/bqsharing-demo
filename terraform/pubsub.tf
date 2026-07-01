resource "google_pubsub_topic" "instrument_requests" {
  project = var.provider_project_id
  name   = "instrument-requests-topic"
}

resource "google_pubsub_topic_iam_member" "publisher_access" {
  project = var.provider_project_id
  topic   = google_pubsub_topic.instrument_requests.name
  role    = "roles/pubsub.publisher"
  member  = "user:${var.client_user_email}"
}
