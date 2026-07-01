import sys
from google.cloud import bigquery_analyticshub_v1

def subscribe_to_listing():
    provider_project = sys.argv[1] if len(sys.argv) > 1 else "genaillentsearch"
    client_project = sys.argv[2] if len(sys.argv) > 2 else "cleanroomdemo-471909"
    client_dataset = sys.argv[3] if len(sys.argv) > 3 else "shared_equities_views"

    client = bigquery_analyticshub_v1.AnalyticsHubServiceClient()

    listing_name = f"projects/{provider_project}/locations/us-central1/dataExchanges/tick_data_exchange/listings/market_data_listing"
    
    destination_dataset = bigquery_analyticshub_v1.DestinationDataset(
        dataset_reference=bigquery_analyticshub_v1.DestinationDatasetReference(
            dataset_id=client_dataset,
            project_id=client_project
        ),
        location="us-central1"
    )

    print(f"Subscribing to listing {listing_name}...")
    try:
        request = bigquery_analyticshub_v1.SubscribeListingRequest(
            name=listing_name,
            destination_dataset=destination_dataset
        )
        response = client.subscribe_listing(request=request)
        print(f"Subscription successful! Linked dataset created at: projects/{client_project}/datasets/{client_dataset}")
        print(f"Subscription details: {response.subscription}")
    except Exception as e:
        print(f"Subscription failed: {e}")

if __name__ == "__main__":
    subscribe_to_listing()
