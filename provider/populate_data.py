import sys
import datetime
import random
from google.cloud import bigquery

def populate():
    # Allow project ID override from command line arguments
    project_id = sys.argv[1] if len(sys.argv) > 1 else None
    
    # Initialize client (will use default credentials if project_id is None)
    client = bigquery.Client(project=project_id)
    project_id = client.project
    
    dataset_id = "raw_exchange_data"
    
    # Define schemas to prevent BigQuery Load Jobs from overriding and drifting the Terraform schema
    ref_schema = [
        bigquery.SchemaField("instrument_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("name", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("sector", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("currency", "STRING", mode="NULLABLE"),
    ]

    ticks_schema = [
        bigquery.SchemaField("timestamp", "TIMESTAMP", mode="REQUIRED"),
        bigquery.SchemaField("instrument_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("price", "NUMERIC", mode="REQUIRED"),
        bigquery.SchemaField("volume", "INTEGER", mode="REQUIRED"),
    ]

    print(f"Populating data for project {project_id}, dataset {dataset_id}")
    
    exchanges = {
        "lse": {
            "ref": [
                {"instrument_id": "VOD", "name": "Vodafone Group Plc", "sector": "Telecommunications"},
                {"instrument_id": "BP", "name": "BP Plc", "sector": "Oil & Gas"},
                {"instrument_id": "BARC", "name": "Barclays Plc", "sector": "Financial Services"},
                {"instrument_id": "AZN", "name": "AstraZeneca Plc", "sector": "Healthcare"},
                {"instrument_id": "HSBA", "name": "HSBC Holdings Plc", "sector": "Financial Services"},
            ],
            "price_range": (1.0, 5.0)
        },
        "nyse": {
            "ref": [
                {"instrument_id": "JPM", "name": "JPMorgan Chase & Co.", "sector": "Financial Services"},
                {"instrument_id": "XOM", "name": "Exxon Mobil Corp.", "sector": "Energy"},
                {"instrument_id": "DIS", "name": "The Walt Disney Co.", "sector": "Entertainment"},
                {"instrument_id": "KO", "name": "The Coca-Cola Co.", "sector": "Consumer Goods"},
                {"instrument_id": "WMT", "name": "Walmart Inc.", "sector": "Retail"},
            ],
            "price_range": (50.0, 200.0)
        },
        "nasdaq": {
            "ref": [
                {"instrument_id": "AAPL", "name": "Apple Inc.", "sector": "Technology"},
                {"instrument_id": "MSFT", "name": "Microsoft Corp.", "sector": "Technology"},
                {"instrument_id": "AMZN", "name": "Amazon.com Inc.", "sector": "E-Commerce"},
                {"instrument_id": "GOOG", "name": "Alphabet Inc.", "sector": "Technology"},
                {"instrument_id": "TSLA", "name": "Tesla Inc.", "sector": "Automotive"},
            ],
            "price_range": (100.0, 400.0)
        },
        "turquoise": {
            "ref": [
                {"instrument_id": "VOD", "name": "Vodafone Group Plc (Turquoise)", "sector": "Telecommunications"},
                {"instrument_id": "AAPL", "name": "Apple Inc. (Turquoise)", "sector": "Technology"},
                {"instrument_id": "JPM", "name": "JPMorgan Chase & Co. (Turquoise)", "sector": "Financial Services"},
                {"instrument_id": "BP", "name": "BP Plc (Turquoise)", "sector": "Oil & Gas"},
            ],
            "price_range": (5.0, 150.0)
        }
    }
    
    # 1. Populate Reference Tables
    for ex, config in exchanges.items():
        ref_table_id = f"{project_id}.{dataset_id}.{ex}_ref"
        print(f"Populating reference table {ref_table_id}...")
        
        # Ensure rows include currency or nullable fields if defined in schema
        ref_rows = []
        for item in config["ref"]:
            ref_rows.append({
                "instrument_id": item["instrument_id"],
                "name": item["name"],
                "sector": item["sector"],
                "currency": "USD" if ex != "lse" else "GBX"
            })
            
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            schema=ref_schema
        )
        try:
            job = client.load_table_from_json(ref_rows, ref_table_id, job_config=job_config)
            job.result()
            print(f"Successfully populated reference data for {ex}")
        except Exception as e:
            print(f"Error inserting ref rows: {e}")
            sys.exit(1)
        
    # 2. Populate Ticks Tables
    for ex, config in exchanges.items():
        ticks_table_id = f"{project_id}.{dataset_id}.{ex}_ticks"
        print(f"Populating ticks table {ticks_table_id}...")
        
        ticks = []
        now = datetime.datetime.now(datetime.timezone.utc)
        
        # Generate ~50 ticks per instrument
        for item in config["ref"]:
            symbol = item["instrument_id"]
            start_price = random.uniform(*config["price_range"])
            
            for i in range(50):
                # Ticks spread over the last 2 hours
                tick_time = now - datetime.timedelta(seconds=random.randint(0, 7200))
                price_delta = random.uniform(-1.0, 1.0) * (start_price * 0.01)
                price = round(max(0.1, start_price + price_delta), 4)
                volume = random.randint(10, 1000)
                
                ticks.append({
                    "timestamp": tick_time.isoformat(),
                    "instrument_id": symbol,
                    "price": str(price),
                    "volume": volume
                })
                
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            schema=ticks_schema
        )
        try:
            job = client.load_table_from_json(ticks, ticks_table_id, job_config=job_config)
            job.result()
            print(f"Successfully populated ticks data for {ex}")
        except Exception as e:
            print(f"Error inserting tick rows: {e}")
            sys.exit(1)
        
if __name__ == "__main__":
    populate()
