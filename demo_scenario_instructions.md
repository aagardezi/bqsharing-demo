# Customer Demo Script: Dynamic BigQuery Data Entitlement

This guide provides a step-by-step script for running a live demonstration of the dynamic data entitlement solution. 

The demo showcases how a market data provider (e.g., LSEG) can securely share equities tick history on GCP BigQuery with a buy-side customer (e.g., a quantitative hedge fund) on a **zero-copy, dynamically entitled** basis.

---

## Demo Overview & Value Pitch
- **No Data Duplication**: The data remains physically in the provider's project. The client queries it in place via Analytics Hub listings.
- **Granular Security**: The client only sees data for instruments (tickers) they are currently licensed to subscribe to.
- **On-Demand Agility**: Ticker entitlements are updated in real-time via Pub/Sub and automated Cloud Run functions, bypassing manual database administration.

---

## Pre-requisites & Setup
Ensure the provider infrastructure is fully deployed and seeded before beginning. 
If not already done, execute:
```bash
./scripts/setup_provider.sh genaillentsearch
```

---

## E2E Demonstration Steps

### Step 1: Subscribe the Client
*Act as the client user (`client-user@example.com`) authenticated on the client project (`cleanroomdemo-471909`).*

First, subscribe the client to the provider's listing. This creates a read-only linked dataset in the client's workspace:
```bash
./scripts/test_client.sh genaillentsearch cleanroomdemo-471909 shared_equities_views "VOD AAPL"
```
*(This command will execute the subscription and initial querying automatically).*

**What to explain to the customer:**
> "We have subscribed our workspace to the LSEG Listing on Analytics Hub. This creates a linked dataset pointing directly to the LSEG shared views. No data has been copied to our project, meaning LSEG maintains absolute custody and we avoid redundant storage costs."

---

### Step 2: Show the Initial Locked State
Query the linked dataset views in the client project (e.g., using the BigQuery Console or our query script).
```bash
python3 client/query_data.py cleanroomdemo-471909 shared_equities_views
```

**Expected Output:**
All queries return **0 rows**:
```text
--- Querying LSE REF VIEW (cleanroomdemo-471909.shared_equities_views.lse_ref_view) ---
Query returned 0 rows.
--- Querying LSE TICKS VIEW (cleanroomdemo-471909.shared_equities_views.lse_ticks_view) ---
Query returned 0 rows.
```

**What to explain to the customer:**
> "Initially, because our subscription list is empty, all shared views default to returning 0 rows. We have access to the schema and table headers, but the data itself is securely hidden from query execution."

---

### Step 3: Request Instruments (Granting Entitlements)
Request tick data for specific symbols: **VOD** (LSE exchange) and **AAPL** (NASDAQ exchange). We do this by publishing the ticker list to LSEG's entitlement Pub/Sub topic:
```bash
python3 client/publish_request.py genaillentsearch VOD AAPL
```

**Expected Output:**
```text
Publishing requested instruments ['VOD', 'AAPL'] to topic projects/genaillentsearch/topics/instrument-requests-topic...
Published message ID: 20314405726975140
```

**What to explain to the customer:**
> "We just published a subscription update requesting data for VOD and AAPL. In LSEG's project, this triggers a serverless Cloud Function. It sanitizes our inputs to prevent SQL injection and dynamically updates the SQL query definitions of the shared views in real-time."

---

### Step 4: Verify Dynamic Access
Wait 5 seconds for view updates to propagate, then query the views again:
```bash
python3 client/query_data.py cleanroomdemo-471909 shared_equities_views
```

**Expected Output:**
- **LSE** view returns **VOD** data.
- **NASDAQ** view returns **AAPL** data.
- **NYSE** view (no tickers requested) returns **0 rows**.
```text
--- Querying LSE REF VIEW (cleanroomdemo-471909.shared_equities_views.lse_ref_view) ---
Query returned 1 rows.
instrument_id | name | sector | currency
VOD | Vodafone Group Plc | Telecommunications | GBX

--- Querying NYSE REF VIEW (cleanroomdemo-471909.shared_equities_views.nyse_ref_view) ---
Query returned 0 rows.

--- Querying NASDAQ REF VIEW (cleanroomdemo-471909.shared_equities_views.nasdaq_ref_view) ---
Query returned 1 rows.
instrument_id | name | sector | currency
AAPL | Apple Inc. | Technology | USD
```

**What to explain to the customer:**
> "Without copying any files or manual database schema alterations, our views have dynamically updated. We now see tick logs and metadata for VOD and AAPL. However, because we did not license NYSE data in this request, the NYSE view remains completely locked."

---

### Step 5: Shift Subscription (Real-time Change)
Demonstrate how subscription changes are processed instantly. Let's remove our request for VOD and AAPL and request **MSFT** (NASDAQ) and **JPM** (NYSE) instead:
```bash
python3 client/publish_request.py genaillentsearch MSFT JPM
```

Wait 5 seconds, then query the views once more:
```bash
python3 client/query_data.py cleanroomdemo-471909 shared_equities_views
```

**Expected Output:**
- **LSE** view now returns **0 rows** (VOD access is revoked).
- **NYSE** view returns **JPM** data (JPM access is granted).
- **NASDAQ** view returns **MSFT** data (AAPL is gone, MSFT is present).
```text
--- Querying LSE REF VIEW ---
Query returned 0 rows.

--- Querying NYSE REF VIEW ---
Query returned 1 rows.
instrument_id | name | sector | currency
JPM | JPMorgan Chase & Co. | Financial Services | USD

--- Querying NASDAQ REF VIEW ---
Query returned 1 rows.
instrument_id | name | sector | currency
MSFT | Microsoft Corp. | Technology | USD
```

**What to explain to the customer:**
> "By shifting our subscription parameters, our access is immediately modified. Access to VOD and AAPL was instantly revoked, and we now query MSFT and JPM. The entire lifecycle is automated, policy-driven, and executes with sub-second latency."

---

## Clean-up & Teardown
Once the demo is complete, run the teardown script using provider credentials to wipe all resources and avoid any cloud costs:
```bash
./scripts/teardown.sh genaillentsearch cleanroomdemo-471909 shared_equities_views
```
