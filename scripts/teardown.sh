#!/bin/bash
set -e
PROVIDER_PROJECT=${1:-"genaillentsearch"}
CLIENT_PROJECT=${2:-"cleanroomdemo-471909"}
CLIENT_DATASET=${3:-"shared_equities_views"}

echo "========================================================="
echo "Tearing down BQ Sharing Demo..."
echo "Provider Project: $PROVIDER_PROJECT"
echo "Client Project:   $CLIENT_PROJECT"
echo "Client Dataset:   $CLIENT_DATASET"
echo "========================================================="

TERRAFORM_CMD="terraform"
if ! command -v terraform &> /dev/null; then
    if [ -f "$HOME/.terraform/bin/terraform" ]; then
        TERRAFORM_CMD="$HOME/.terraform/bin/terraform"
    else
        echo "Error: terraform command not found."
        exit 1
    fi
fi

echo "Step 1: Deleting Analytics Hub listing and exchange..."
uv run --default-index https://pypi.org/simple --with google-cloud-bigquery-analyticshub provider/delete_exchange.py "$PROVIDER_PROJECT"

echo ""
echo "Step 2: Destroying provider infrastructure via Terraform..."
$TERRAFORM_CMD -chdir=terraform destroy -auto-approve -var="provider_project_id=$PROVIDER_PROJECT"

echo ""
echo "Step 3: Deleting client linked dataset..."
export PATH=/usr/local/google/home/sgardezi/google-cloud-sdk/bin:$PATH
bq rm -r -f -d "$CLIENT_PROJECT:$CLIENT_DATASET" || true

echo ""
echo "========================================================="
echo "Teardown completed!"
echo "========================================================="
