#!/bin/bash
set -e
PROVIDER_PROJECT=${1:-"genaillentsearch"}
CLIENT_PROJECT=${2:-"cleanroomdemo-471909"}
CLIENT_DATASET=${3:-"shared_equities_views"}
INSTRUMENTS=${4:-"VOD AAPL JPM"}

echo "========================================================="
echo "Running Client End-to-End Test..."
echo "Provider Project: $PROVIDER_PROJECT"
echo "Client Project:   $CLIENT_PROJECT"
echo "Client Dataset:   $CLIENT_DATASET"
echo "Requested Instruments: $INSTRUMENTS"
echo "========================================================="

echo ""
echo "Step 1: Subscribing client to Analytics Hub listing..."
uv run --default-index https://pypi.org/simple --with google-cloud-bigquery-analyticshub client/subscribe.py "$PROVIDER_PROJECT" "$CLIENT_PROJECT" "$CLIENT_DATASET"

echo ""
echo "Step 2: Querying initial views (expected: 0 rows)..."
uv run --default-index https://pypi.org/simple --with google-cloud-bigquery client/query_data.py "$CLIENT_PROJECT" "$CLIENT_DATASET"

echo ""
echo "Step 3: Requesting instruments ($INSTRUMENTS)..."
uv run --default-index https://pypi.org/simple --with google-cloud-pubsub client/publish_request.py "$PROVIDER_PROJECT" $INSTRUMENTS

echo ""
echo "Waiting 10 seconds for Cloud Function view updates to propagate..."
sleep 10

echo ""
echo "Step 4: Querying views again to verify dynamic updates..."
uv run --default-index https://pypi.org/simple --with google-cloud-bigquery client/query_data.py "$CLIENT_PROJECT" "$CLIENT_DATASET"

echo ""
echo "========================================================="
echo "Client test completed!"
echo "========================================================="
