
import sys
from google.cloud import bigquery

def query_data():
    client_project = sys.argv[1] if len(sys.argv) > 1 else "cleanroomdemo-471909"
    client_dataset = sys.argv[2] if len(sys.argv) > 2 else "shared_equities_views"
    
    # If a third argument is passed, query only that exchange, otherwise query all
    exchanges = [sys.argv[3].lower()] if len(sys.argv) > 3 else ["lse", "nyse", "nasdaq", "turquoise"]

    client = bigquery.Client(project=client_project)

    for exchange in exchanges:
        for suffix in ["ref_view", "ticks_view"]:
            table_id = f"{client_project}.{client_dataset}.{exchange}_{suffix}"
            query = f"SELECT * FROM `{table_id}` LIMIT 10"
            print(f"\n--- Querying {exchange.upper()} {suffix.replace('_', ' ').upper()} ({table_id}) ---")
            try:
                query_job = client.query(query)
                results = list(query_job.result())
                print(f"Query returned {len(results)} rows.")
                if results:
                    headers = list(results[0].keys())
                    print(" | ".join(headers))
                    print("-" * (len(" | ".join(headers)) + 4))
                    for row in results:
                        row_dict = dict(row)
                        # Format timestamp if present
                        values = []
                        for h in headers:
                            val = row_dict.get(h)
                            if val is not None:
                                values.append(str(val))
                            else:
                                values.append("NULL")
                        print(" | ".join(values))
            except Exception as e:
                print(f"Query on {table_id} failed: {e}")

if __name__ == "__main__":
    query_data()
