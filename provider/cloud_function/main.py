import os
import json
import base64
import functions_framework
from google.cloud import bigquery

@functions_framework.cloud_event
def update_views(cloud_event):
    # Parse the pubsub message
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode("utf-8")
    print(f"Received pubsub message: {pubsub_message}")
    
    try:
        payload = json.loads(pubsub_message)
    except Exception as e:
        print(f"Failed to parse JSON message: {e}")
        return
        
    instruments = payload.get("instruments", [])
    print(f"Instruments requested: {instruments}")
    
    # Sanitize inputs to prevent SQL injection
    safe_instruments = []
    for inst in instruments:
        sanitized = "".join(c for c in str(inst) if c.isalnum() or c in [".", "-", "/"])
        if sanitized:
            safe_instruments.append(sanitized)
            
    print(f"Sanitized instruments: {safe_instruments}")
    
    project_id = os.environ.get("PROVIDER_PROJECT_ID")
    raw_dataset = os.environ.get("RAW_DATASET_ID")
    views_dataset = os.environ.get("VIEWS_DATASET_ID")
    
    bq_client = bigquery.Client()
    
    exchanges = ["lse", "nyse", "nasdaq", "turquoise"]
    types = ["ticks", "ref"]
    
    for ex in exchanges:
        for t in types:
            view_id = f"{project_id}.{views_dataset}.{ex}_{t}_view"
            raw_table_id = f"{project_id}.{raw_dataset}.{ex}_{t}"
            
            # Construct the SQL
            if safe_instruments:
                inst_list_str = ", ".join(f"\"{inst}\"" for inst in safe_instruments)
                query = f"SELECT * FROM `{raw_table_id}` WHERE instrument_id IN ({inst_list_str})"
            else:
                query = f"SELECT * FROM `{raw_table_id}` WHERE FALSE"
            
            # Update the view definition
            try:
                view = bq_client.get_table(view_id)
                view.view_query = query
                bq_client.update_table(view, ["view_query"])
                print(f"Successfully updated view {view_id} to: {query}")
            except Exception as e:
                print(f"Error updating view {view_id}: {e}")
