output "pubsub_topic_id" {
  value       = google_pubsub_topic.instrument_requests.id
  description = "The ID of the Pub/Sub topic to publish instrument requests to"
}

output "data_exchange_id" {
  value       = google_bigquery_analytics_hub_data_exchange.tick_data_exchange.id
  description = "The ID of the Analytics Hub data exchange"
}

output "listing_id" {
  value       = google_bigquery_analytics_hub_listing.market_data_listing.id
  description = "The ID of the Analytics Hub listing"
}

output "views_dataset_id" {
  value       = google_bigquery_dataset.views_dataset.dataset_id
  description = "The dataset ID containing shared customer views"
}

output "raw_dataset_id" {
  value       = google_bigquery_dataset.raw_dataset.dataset_id
  description = "The dataset ID containing raw exchange data"
}
