resource "google_bigquery_analytics_hub_data_exchange" "tick_data_exchange" {
  project          = var.provider_project_id
  data_exchange_id = "tick_data_exchange"
  display_name     = "Equities Tick Data Exchange"
  location         = var.region
  description      = "Exchange hosting tick data views for exchanges: LSE, NYSE, NASDAQ, Turquoise"
}

resource "google_bigquery_analytics_hub_listing" "market_data_listing" {
  project          = var.provider_project_id
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.tick_data_exchange.data_exchange_id
  listing_id       = "market_data_listing"
  display_name     = "Customer Market Data Custom Views"
  location         = var.region
  description      = "Listing for views filtered by client requested instrument list"

  bigquery_dataset {
    dataset = google_bigquery_dataset.views_dataset.id
  }
}

resource "google_bigquery_analytics_hub_listing_iam_member" "subscriber_access" {
  project          = var.provider_project_id
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.tick_data_exchange.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.market_data_listing.listing_id
  location         = var.region
  role             = "roles/analyticshub.subscriber"
  member           = "user:${var.client_user_email}"
}

resource "google_bigquery_analytics_hub_listing_iam_member" "subscriber_access_developer" {
  project          = var.provider_project_id
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.tick_data_exchange.data_exchange_id
  listing_id       = google_bigquery_analytics_hub_listing.market_data_listing.listing_id
  location         = var.region
  role             = "roles/analyticshub.subscriber"
  member           = "user:${var.provider_developer_email}"
}
