# Fintech/Banking Data Engineering Project

A containerized ELT data platform using Docker Compose with Airflow, PostgreSQL, PySpark, dbt, and PowerBI.

## Architecture

This project implements a **Bronze-Silver-Gold** data lakehouse architecture for a LATAM Fintech/Banking dataset:

- **Bronze Layer**: Raw JSON ingestion from S3 into PostgreSQL (`jsonb`)
- **Silver Layer (PySpark)**: Flatten nested arrays, deduplicate
- **Silver Layer (dbt)**: Clean, standardize, and normalize PySpark output; flatten nested objects
- **Gold Layer (dbt)**: Business-ready analytics and aggregations answering 24 business questions
- **PowerBI**: 4-page dashboard connected to Gold layer tables

```
S3 (JSON) → Airflow → Bronze → PySpark (Silver) → dbt (Silver) → dbt (Gold) → PowerBI
```

## Project Structure

```
qversity-data-2026-<city>-<firstname><lastname>/
├── dags/                     # Airflow DAG definitions
│   └── example_dag.py        # Placeholder pipeline DAG
├── spark/                    # PySpark scripts (NEW in v2)
├── dbt/                      # dbt project
│   ├── models/
│   │   ├── bronze/           # Raw data staging
│   │   ├── silver/           # Cleaned and normalized data
│   │   └── gold/             # Business analytics
│   ├── tests/                # dbt tests
│   ├── dbt_project.yml       # dbt configuration
│   └── profiles.yml          # Database connections
├── powerbi/                  # PowerBI deliverables (NEW in v2)
│   ├── dashboard.pbix        # PowerBI file (you create this)
│   └── screenshots/          # Dashboard page screenshots
├── data/
│   └── raw/                  # Raw input data
├── docker-compose.yml        # Docker environment setup
├── env.example               # Environment variables template
├── requirements.txt          # Python dependencies
├── .gitignore
├── .pre-commit-config.yaml   # Code quality hooks
└── README.md                 # This file
```
## PowerBI DashBoard
<img width="496" height="710" alt="image" src="https://github.com/user-attachments/assets/4cd4f383-75c3-48d0-aea5-7837fe8195d5" />
Choose "Obtain Data"
Then PostgreSQL database
<img width="984" height="868" alt="image" src="https://github.com/user-attachments/assets/8d0a6419-fae2-4cc1-ae9b-818d48c12711" />
<img width="1072" height="525" alt="image" src="https://github.com/user-attachments/assets/c0f2a4ca-ab38-4840-9734-743bea43ee1a" />
Enter database values.
If prompted for username and password use "qversity-admin" for both username and password.





## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- PowerBI Desktop (for dashboard creation)

### Setup

1. **Clone the repository and setup environment**:
```bash
git clone qversity-data-2026-medellin-davidgrisales
cd qversity-data-2026-medellin-davidgrisales
cp env.example .env
# If you have a MacBook, execute the following commands
mkdir -p logs dags plugins
sudo chown -R 50000:0 logs dags plugins
sudo chmod -R 775 logs dags plugins
```

2. **Start services**:
```bash
docker compose up -d --build
```

3. **Verify services are running**:
```bash
docker compose ps
```

4. **Access Airflow UI**: http://localhost:8080 (admin/admin)

5. **Trigger the pipeline** (once you've built it):
```bash
docker compose exec airflow airflow dags unpause qversity_fintech_pipeline
docker compose exec airflow airflow dags trigger qversity_fintech_pipeline
```

## Access Points

| Service | URL / Connection | Credentials |
|---------|-----------------|-------------|
| Airflow UI | http://localhost:8080 | admin / admin |
| PostgreSQL | localhost:5432 | qversity-admin / qversity-admin |
| Database | qversity | — |

## Common Commands

### Airflow
```bash
# View logs
docker compose logs -f airflow

# List DAGs
docker compose exec airflow airflow dags list

# Trigger DAG
docker compose exec airflow airflow dags trigger qversity_fintech_pipeline

# Check DAG run status
docker compose exec airflow airflow dags list-runs -d qversity_fintech_pipeline
```

### dbt
```bash
# Enter dbt container
docker compose exec dbt bash

# Run all models
dbt run

# Run specific layer
dbt run --models bronze
dbt run --models silver
dbt run --models gold

# Test data quality
dbt test

# List models
dbt ls --resource-type model
```

### Database Access
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U qversity-admin -d qversity

# View schemas
\dn

# View tables in a schema
\dt bronze.*
\dt silver.*
\dt gold.*

# Describe a table
\d <schema>.<table_name>
```



## Git Tags (Milestones)

Submit your work incrementally:

```bash
git tag -a v0.1.0-bronze -m "Bronze layer complete"
git tag -a v0.2.0-silver -m "Silver layer complete"
git tag -a v0.3.0-gold -m "Gold layer complete"
git tag -a v0.4.0-powerbi -m "PowerBI dashboard complete"
git tag -a v1.0.0 -m "Final submission"
```

## Cleanup

```bash
# Stop services
docker compose down

# Remove volumes (deletes all data)
docker compose down -v

# Remove images
docker compose down -v --rmi local
```


# Data Cleaning Decisions — Qversity Silver Layer

Source: `silver` schema — tables `stg_customers`, `stg_accounts`, `stg_transactions`, `stg_loans`

---

## Customers (`stg_customers`)

### City
- Strip leading/trailing whitespace.
- Use `pg_trgm` similarity to detect and correct misspelled city names, retaining the most frequent variant as the canonical form.

### Email
- Strip whitespace and convert to lowercase.
- For records missing `@`, insert it after the `last_name` occurrence in the email string (verified that all invalid emails contain the last name).

### First Name / Last Name
- Normalize to lowercase. Capitalization can be applied at the presentation layer if needed.

### Phone Number
- Standardize to **E.164** format: keep only digits and a leading `+`.
- Add the country code for numbers that omit it.

### Date of Birth
- Unify four coexisting formats into a single standard (`YYYY-MM-DD`):
  - `MM-DD-YYYY`
  - `YYYY-MM-DD`
  - `DD/MM/YYYY`

### Gender
- Accepted values: `M`, `F`, `Other`.
- Missing or unrecognized values (e.g. `"unknown"`) are set to `NULL`; representation of nulls is delegated to the presentation layer.

### Nationality
- No missing values or value corrections needed.
- Enforce consistent uppercase formatting.

### Country
- No cleaning required.

### Customer Segment
- Lowercase and trim all values.
- Translate Spanish variants:

| Original       | Standardized    |
|----------------|-----------------|
| `banca_privada` | `private_banking` |
| `minorista`    | `retail`         |
| `pyme`         | `sme`            |

### Status
- Lowercase and trim all values.
- Translate Spanish variants:

| Original    | Standardized |
|-------------|--------------|
| `activo`    | `active`     |
| `inactivo`  | `inactive`   |
| `suspendido`| `suspended`  |
| `cerrado`   | `closed`     |

### KYC Status
- Lowercase all values. No null handling required.
- Accepted values: `verified`, `pending`, `expired`, `rejected`.

### Address
- Convert literal null representations (`'null'`, `'n/a'`, etc.) to actual `NULL`.
- Normalize whitespace (collapse multiple spaces, strip leading/trailing).

### Risk Score
- No modifications required.

### Relationship Manager
- Convert literal null strings (15 distinct representations found) to actual `NULL`.
- Given the volume of null representations, placing relationship managers in a dedicated reference table is recommended.

### Latitude / Longitude
- Valid ranges: lat ∈ [−90, 90], lon ∈ [−180, 180].
- For out-of-range coordinates, replace with the **median** lat/lon of valid records for the same city/country.

### Digital Engagement (JSON)
- `mobile_app_registered`, `web_banking_registered`, `push_notifications`, `paperless_statements`: no cleaning required.
- `last_login_date`: normalize date format.
- `avg_monthly_logins`: remove non-numeric values; enforce integer type.
- `preferred_channel`: no cleaning required.

### Credit Info (JSON)
- `credit_score`: no nulls; remove or flag any negative values.
- `currency`: no cleaning required.
- `utilization_pct`: remove non-numeric strings; enforce decimal type.
- `total_limit` / `total_used`: remove non-numeric strings; enforce decimal type.
- `num_credit_accounts`, `oldest_account_age_months`, `late_payments_12m`, `inquiries_6m`: enforce integer type; no null issues found.
- `bankruptcy_flag`: no cleaning required.

---

## Accounts (`stg_accounts`)

### Account ID
- No duplicates found; no cleaning required.

### Account Type
- Trim and lowercase. EDA confirmed values are already lowercase, but the transformation is enforced for consistency.

### Currency
- Already normalized (uppercase ISO codes). No changes required.

### Balance
- No null values detected after review.
- No cleaning required.

### Credit Limit
- Only `credit_card` accounts have a credit limit; no cross-type contamination detected.
- Convert from scientific notation to standard decimal format.

### Interest Rate
- No null or out-of-range values. No cleaning required.

### Opened Date
- Unify four coexisting formats into `YYYY-MM-DD`:
  - `YYYY-MM-DD`
  - `DD/MM/YYYY`
  - `MM-DD-YYYY`
  - `YYYYMMDD`
- Two null values present; retain as `NULL` (relevant for activity tracking).

### Status
- Lowercase and trim all values.
- Translate Spanish variants:

| Original   | Standardized |
|------------|--------------|
| `activo`   | `active`     |
| `cerrado`  | `closed`     |
| `congelado`| `frozen`     |

### Branch Code
- Trim leading/trailing whitespace. No other cleaning required.

---

## Transactions (`stg_transactions`)

### Customer ID / Account ID
- Referential integrity verified: all IDs exist in their parent tables. No cleaning required.

### Date
- Unify four coexisting formats into `YYYY-MM-DD`:
  - `YYYY-MM-DD`
  - `DD/MM/YYYY`
  - `MM-DD-YYYY`
  - `YYYYMMDD`
- Null dates retained as `NULL`.

### Amount
- No cleaning required beyond verifying range.

### Currency
- Already normalized. Enforce format consistency.

### Type
- Lowercase and trim.
- Translate Spanish variants:

| Original       | Standardized |
|----------------|--------------|
| `retiro`       | `withdrawal` |
| `transferencia`| `transfer`   |
| `reembolso`    | `refund`     |
| `pago`         | `payment`    |
| `deposito`     | `deposit`    |
| `comision`     | `fee`        |

### Category
- Lowercase, trim, and handle improper null representations.

### Merchant
- Convert literal null placeholders (`'NA'`, `'N/A'`, etc.) to actual `NULL`.

### Channel
- Already normalized. Enforce lowercase and trimming.

### Status
- Lowercase and trim. No null handling required.

### Description
- Collapse multiple whitespace characters into a single space.

---

## Loans (`stg_loans`)

### Loan ID
- No duplicates found; no cleaning required.

### Type
- Lowercase and trim. No translation needed.

### Currency
- No null values. No cleaning required.

### Principal
- Null values can be deterministically imputed using the standard loan amortization formula from `monthly_payment`, `interest_rate`, and `term_months` where those fields are available.

### Outstanding Balance
- No deterministic imputation method available for nulls; retain as `NULL`.
- Note: some loans show full repayment ahead of the original schedule.

### Interest Rate
- No nulls or negative values. No cleaning required.

### Term Months
- No nulls or out-of-range values. No cleaning required.

### Monthly Payment
- Null only when `principal` is also null. No independent cleaning required.

### Start Date / End Date
- Unify four coexisting formats into `YYYY-MM-DD`:
  - `YYYY-MM-DD`
  - `DD/MM/YYYY`
  - `MM-DD-YYYY`
  - `YYYYMMDD`
- Null dates retained as `NULL`.

### Status
- Lowercase and trim. No null handling required.

### Days Past Due
- No nulls or negative values. Enforce integer type constraint.

### Collateral Type
- Multiple null placeholders detected; normalize all to actual `NULL`.

## Deduplication Reasoning
It was found that duplicate data from raw was the same after removing whitespaces and lowercasing the data, so simply deduplicating by string was enough.

# ERD
<img width="1225" height="620" alt="image" src="https://github.com/user-attachments/assets/ee5d22ee-3a8a-43ad-96b9-9e306d05937e" />


## Participant

- **Name**: David Grisales Posada
- **Email**: daviddgp04@hotmail.com
- **City**: Medellin
- **Cohort**: Qversity 2026
