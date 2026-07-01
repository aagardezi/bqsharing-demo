import sys
from google.cloud import bigquery_analyticshub_v1

def cleanup():
    project = sys.argv[1] if len(sys.argv) > 1 else 'genaillentsearch'
    location = 'us-central1'
    exchange_id = 'tick_data_exchange'
    listing_id = 'market_data_listing'
    
    client = bigquery_analyticshub_v1.AnalyticsHubServiceClient()
    
    listing_name = f'projects/{project}/locations/{location}/dataExchanges/{exchange_id}/listings/{listing_id}'
    exchange_name = f'projects/{project}/locations/{location}/dataExchanges/{exchange_id}'
    
    print(f'Deleting listing {listing_name}...')
    try:
        client.delete_listing(name=listing_name)
        print('Listing deleted successfully.')
    except Exception as e:
        print(f'Listing delete failed or already deleted: {e}')
        
    print(f'Deleting exchange {exchange_name}...')
    try:
        client.delete_data_exchange(name=exchange_name)
        print('Exchange deleted successfully.')
    except Exception as e:
        print(f'Exchange delete failed or already deleted: {e}')

if __name__ == '__main__':
    cleanup()
