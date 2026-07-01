#!/bin/bash
set -e
PROVIDER_PROJECT=${1:-"genaillentsearch"}

echo "========================================================="
echo "Initializing and deploying Provider Infrastructure..."
echo "Project: $PROVIDER_PROJECT"
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

$TERRAFORM_CMD -chdir=terraform init
$TERRAFORM_CMD -chdir=terraform apply -auto-approve -var="provider_project_id=$PROVIDER_PROJECT"

echo ""
echo "========================================================="
echo "Seeding BigQuery raw tables with mock equities tick data..."
echo "========================================================="

uv run --default-index https://pypi.org/simple --with google-cloud-bigquery provider/populate_data.py "$PROVIDER_PROJECT"

echo ""
echo "========================================================="
echo "Provider setup completed successfully!"
echo "========================================================="
