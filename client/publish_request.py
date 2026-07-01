import json
import sys
from google.cloud import pubsub_v1

def publish_request():
    provider_project = "genaillentsearch"
    topic_id = "instrument-requests-topic"
    
    # Check if arguments are provided:
    # Option 1: python3 publish_request.py <provider_project_id> <instrument1> [instrument2] ...
    # Option 2: python3 publish_request.py <instrument1> [instrument2] ... (defaults project to genaillentsearch)
    if len(sys.argv) > 1:
        if sys.argv[1].islower() and "search" in sys.argv[1]:
            # First argument looks like a project ID
            provider_project = sys.argv[1]
            instruments = sys.argv[2:] if len(sys.argv) > 2 else ["VOD", "AAPL"]
        else:
            # First argument is a symbol
            instruments = sys.argv[1:]
    else:
        # Default test instruments representing LSE, NYSE, NASDAQ, Turquoise
        instruments = ["VOD", "AAPL", "JPM", "BP"]

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(provider_project, topic_id)

    payload = {"instruments": instruments}
    data_str = json.dumps(payload)
    data = data_str.encode("utf-8")

    print(f"Publishing requested instruments {instruments} to topic {topic_path}...")
    try:
        future = publisher.publish(topic_path, data)
        message_id = future.result()
        print(f"Published message ID: {message_id}")
    except Exception as e:
        print(f"Publish failed: {e}")

if __name__ == "__main__":
    publish_request()
