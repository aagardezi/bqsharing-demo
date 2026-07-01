resource "google_bigquery_dataset" "raw_dataset" {
  project    = var.provider_project_id
  dataset_id = "raw_exchange_data"
  location   = var.region
}

resource "google_bigquery_dataset" "views_dataset" {
  project    = var.provider_project_id
  dataset_id = "shared_customer_views"
  location   = var.region
}

# Dataset access authorization: authorize views_dataset on raw_dataset
resource "google_bigquery_dataset_access" "authorized_dataset" {
  project    = var.provider_project_id
  dataset_id = google_bigquery_dataset.raw_dataset.dataset_id

  dataset {
    dataset {
      project_id = var.provider_project_id
      dataset_id = google_bigquery_dataset.views_dataset.dataset_id
    }
    target_types = ["VIEWS"]
  }
}

# Helper local for schemas
locals {
  ticks_schema = jsonencode([
    { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "instrument_id", type = "STRING", mode = "REQUIRED" },
    { name = "price", type = "NUMERIC", mode = "REQUIRED" },
    { name = "volume", type = "INTEGER", mode = "REQUIRED" }
  ])

  ref_schema = jsonencode([
    { name = "instrument_id", type = "STRING", mode = "REQUIRED" },
    { name = "name", type = "STRING", mode = "REQUIRED" },
    { name = "sector", type = "STRING", mode = "NULLABLE" },
    { name = "currency", type = "STRING", mode = "NULLABLE" }
  ])

  exchanges = ["lse", "nyse", "nasdaq", "turquoise"]
}

# Raw Tables
resource "google_bigquery_table" "ticks" {
  for_each            = toset(local.exchanges)
  project             = var.provider_project_id
  dataset_id          = google_bigquery_dataset.raw_dataset.dataset_id
  table_id            = "${each.key}_ticks"
  schema              = local.ticks_schema
  deletion_protection = false
}

resource "google_bigquery_table" "ref" {
  for_each            = toset(local.exchanges)
  project             = var.provider_project_id
  dataset_id          = google_bigquery_dataset.raw_dataset.dataset_id
  table_id            = "${each.key}_ref"
  schema              = local.ref_schema
  deletion_protection = false
}

# Shared Customer Views
resource "google_bigquery_table" "ticks_views" {
  for_each            = toset(local.exchanges)
  project             = var.provider_project_id
  dataset_id          = google_bigquery_dataset.views_dataset.dataset_id
  table_id            = "${each.key}_ticks_view"
  deletion_protection = false

  view {
    use_legacy_sql = false
    query          = "SELECT * FROM `${var.provider_project_id}.${google_bigquery_dataset.raw_dataset.dataset_id}.${each.key}_ticks` WHERE FALSE"
  }

  lifecycle {
    ignore_changes = [
      view[0].query
    ]
  }

  depends_on = [
    google_bigquery_table.ticks
  ]
}

resource "google_bigquery_table" "ref_views" {
  for_each            = toset(local.exchanges)
  project             = var.provider_project_id
  dataset_id          = google_bigquery_dataset.views_dataset.dataset_id
  table_id            = "${each.key}_ref_view"
  deletion_protection = false

  view {
    use_legacy_sql = false
    query          = "SELECT * FROM `${var.provider_project_id}.${google_bigquery_dataset.raw_dataset.dataset_id}.${each.key}_ref` WHERE FALSE"
  }

  lifecycle {
    ignore_changes = [
      view[0].query
    ]
  }

  depends_on = [
    google_bigquery_table.ref
  ]
}
