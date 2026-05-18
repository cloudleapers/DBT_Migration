# 04 — Day 1 to Day 25 Training Plan

> **Audience:** New team members onboarding to the dbt + Snowflake healthcare platform
> **Duration:** 5 weeks (25 working days), ~3-4 hours per day of structured work
> **Format:** Self-paced with daily checkpoints and weekly quizzes
> **Outcome:** By Day 25, every team member can independently extend the warehouse with new sources, models, and tests

---

## Curriculum Overview

| Week | Theme | Days | Outcome |
|---|---|---|---|
| **Week 1** | Setup & Environment | 1-5 | Working dev environment, all tools installed, can connect to all 3 databases |
| **Week 2** | ELT & Source Loading | 6-10 | Source data populated in Snowflake RAW, Python loader understood |
| **Week 3** | dbt Modeling | 11-15 | Built staging + intermediate + mart models, understand the layers |
| **Week 4** | Testing & Documentation | 16-20 | Can write tests, generate docs, debug failures |
| **Week 5** | Analytics & Capstone | 21-25 | Daily warehouse scenarios, capstone project extending the platform |

Each week ends with a **mini-quiz** (Friday). Week 5 ends with the **Capstone Project**.

---

# Week 1 — Setup & Environment

## Day 1 — Tool Installation

**Objective:** Install everything needed to develop on this project.

### Deliverables
- Python 3.11+ installed and on PATH
- VS Code installed with: dbt Power User extension, Python extension, SQLTools extension, SQLTools PostgreSQL Driver, SQLTools MySQL Driver, SQLTools Snowflake Driver
- Git installed and configured (`git config --global user.name`, `--global user.email`)
- Snowflake free trial account created (https://signup.snowflake.com - 30 days, $400 credits)
- Supabase free account + new project created (https://supabase.com)
- Aiven free trial account + MySQL service created (https://aiven.io - 30 days)

### Verification
```powershell
python --version           # Should show 3.11+
git --version              # Should show 2.x+
code --version             # Should show 1.x+
```

In Snowflake worksheet:
```sql
SELECT CURRENT_VERSION(), CURRENT_USER(), CURRENT_ROLE();
```

### Common Mistakes
- **PATH not set** for Python — re-install and check the "Add to PATH" box
- **Microsoft Store Python alias** — disable it: Settings → Apps → App execution aliases → turn off `python.exe` and `python3.exe`
- **VS Code extensions missing** — the dbt Power User extension is the most important; verify it appears in Extensions sidebar

### Hints
- If `python` doesn't work but `py` does, you have the Python launcher. Either works.
- For Snowflake, write down your **account identifier** from the URL (e.g., `WWLAZGI-XZ78250`). You'll need it daily.

---

## Day 2 — Source Database Setup

**Objective:** Provision and verify both source databases (PostgreSQL on Supabase, MySQL on Aiven).

### Deliverables
- Supabase project active, with credentials saved in a password manager
- Aiven MySQL service running, with credentials saved
- Successful test query against each source database via SQLTools

### Verification
In Supabase SQL editor:
```sql
SELECT version();          -- Should return PostgreSQL version
```

In Aiven SQL editor:
```sql
SELECT VERSION();          -- Should return MySQL version
```

### Common Mistakes
- **Supabase wrong connection string** — there are 3 connection types: direct, transaction pooler, **session pooler**. Use **session pooler** (port 5432, user format `postgres.<project_ref>`). The pooler region matters: `aws-1-ap-southeast-1` not `aws-0-ap-southeast-1`.
- **Aiven SSL not enabled** — Aiven requires SSL by default. Connection will fail without `ssl_disabled: false` setting.
- **Aiven port wrong** — check service overview. Default is NOT 3306; it's a custom port (often in 13xxx range).

### Hints
- Save credentials in a `.env` file early (we'll formalize this in Day 3). Format:
  ```
  PG_HOST=aws-1-ap-southeast-1.pooler.supabase.com
  PG_PORT=5432
  PG_DATABASE=postgres
  PG_USER=postgres.skgngaeanbttwrvlweyd
  PG_PASSWORD=...
  ```

---

## Day 3 — Snowflake Setup + Project Folder

**Objective:** Provision Snowflake environment using the setup SQL and create the project folder structure.

### Deliverables
- Snowflake `HEALTHCARE_DW` database with 6 schemas
- `COMPUTE_WH` warehouse running
- Project folder cloned/created at `C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt`
- `.env` file populated with all credentials

### Steps
1. In Snowflake worksheet, run `sql/snowflake/00_setup.sql` (single click - whole script)
2. Verify with `SHOW DATABASES`, `SHOW SCHEMAS IN HEALTHCARE_DW`, `SHOW WAREHOUSES`
3. Create the project folder structure (use the layout from README)
4. Copy `.env.example` to `.env` and fill in all values

### Verification
```sql
SELECT 'HEALTHCARE_DW exists' AS check
WHERE EXISTS (SELECT 1 FROM SNOWFLAKE.INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'HEALTHCARE_DW');
```

### Common Mistakes
- **Wrong role** — script needs `ACCOUNTADMIN`. Run `USE ROLE ACCOUNTADMIN;` first.
- **`.env` file committed to git** — add it to `.gitignore` immediately (`.env` on its own line).
- **Special characters in passwords** — `@`, `:`, `/`, `?`, `#` need URL encoding when used in connection strings. We handle this in Python with `urllib.parse.quote_plus`.

### Mini-exercise
Create a Snowflake user (other than yourself) with read-only access to MART schema. This teaches role-based access concepts you'll see often in production.

---

## Day 4 — Python Virtual Environment + dbt Installation

**Objective:** Install dbt-core and adapter, configure profiles.yml, verify connection.

### Deliverables
- Virtual environment at `dbt_env/`
- dbt-core 1.11+, dbt-snowflake 1.11+, dbt-postgres 1.10+ installed
- `~/.dbt/profiles.yml` configured for `healthcare_dbt` project
- `dbt debug` returns all green checks

### Steps
```powershell
# 1. Create venv
python -m venv dbt_env

# 2. Activate
dbt_env\Scripts\activate

# 3. Install
pip install dbt-core dbt-snowflake dbt-postgres python-dotenv pandas sqlalchemy snowflake-sqlalchemy snowflake-connector-python pymysql cryptography

# 4. Initialize project (only first time)
dbt init healthcare_dbt    # When prompted choose Snowflake adapter

# 5. Edit profiles.yml at C:\Users\<you>\.dbt\profiles.yml
```

### profiles.yml structure
```yaml
healthcare_dbt:
  outputs:
    dev:
      type: snowflake
      account: WWLAZGI-XZ78250
      user: <your_user>
      password: <your_password>
      role: ACCOUNTADMIN
      database: HEALTHCARE_DW
      warehouse: COMPUTE_WH
      schema: STAGING
      threads: 4
      client_session_keep_alive: false
  target: dev
```

### Verification
```powershell
dbt debug
```
Should show: "All checks passed!"

### Common Mistakes
- **profiles.yml in wrong location** — must be at `C:\Users\<username>\.dbt\profiles.yml`, NOT in the project folder
- **YAML indentation** — YAML is whitespace-sensitive. Use exactly 2 spaces, no tabs
- **Wrong adapter version** — `dbt-mysql` adapter is incompatible with dbt-core 1.11. Don't install it; we use Python loader instead

---

## Day 5 — Connection Testing + Mini-Quiz

**Objective:** End-to-end connection test from Python to all 3 databases. Take the Week 1 quiz.

### Deliverables
- `scripts/test_connections.py` runs and confirms all 3 databases are reachable
- Week 1 mini-quiz answers (below)

### Sample test_connections.py
```python
"""Quick smoke test for all 3 database connections."""
import os
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text
from snowflake.sqlalchemy import URL as snowflake_url
from dotenv import load_dotenv

load_dotenv()

def test_postgres():
    url = (f"postgresql+psycopg2://{quote_plus(os.getenv('PG_USER'))}:"
           f"{quote_plus(os.getenv('PG_PASSWORD'))}@{os.getenv('PG_HOST')}:"
           f"{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}?sslmode=require")
    engine = create_engine(url)
    with engine.connect() as c:
        result = c.execute(text("SELECT version()")).scalar()
    print(f"  PostgreSQL OK: {result[:50]}...")

def test_mysql():
    url = (f"mysql+pymysql://{quote_plus(os.getenv('MYSQL_USER'))}:"
           f"{quote_plus(os.getenv('MYSQL_PASSWORD'))}@{os.getenv('MYSQL_HOST')}:"
           f"{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DATABASE')}")
    engine = create_engine(url, connect_args={'ssl': {'ssl_disabled': False}})
    with engine.connect() as c:
        result = c.execute(text("SELECT VERSION()")).scalar()
    print(f"  MySQL OK: {result}")

def test_snowflake():
    engine = create_engine(snowflake_url(
        account=os.getenv('SF_ACCOUNT'), user=os.getenv('SF_USER'),
        password=os.getenv('SF_PASSWORD'), role=os.getenv('SF_ROLE'),
        database=os.getenv('SF_DATABASE'), warehouse=os.getenv('SF_WAREHOUSE')))
    with engine.connect() as c:
        result = c.execute(text("SELECT CURRENT_VERSION()")).scalar()
    print(f"  Snowflake OK: {result}")

if __name__ == '__main__':
    print("Testing connections...")
    test_postgres(); test_mysql(); test_snowflake()
    print("All connections successful.")
```

### Week 1 Mini-Quiz

1. What's the difference between Supabase's "session pooler" and "transaction pooler"? Which one does our project use and why?
2. Why must passwords be URL-encoded when used in SQLAlchemy connection strings? Give an example of a character that breaks without encoding.
3. What's the purpose of `dbt debug`? What does it check?
4. Where does dbt look for `profiles.yml`? What happens if you put it in your project folder instead?
5. What's the difference between an X-SMALL warehouse and an X-LARGE warehouse in Snowflake? When would you use each?

> **Answers in `05_EXECUTION_LOG_AND_TROUBLESHOOTING.md`** — submit your answers via team Slack/PR before moving to Week 2.

---

# Week 2 — ELT & Source Loading

## Day 6 — PostgreSQL Source Population

**Objective:** Load all 4 PostgreSQL SQL files into Supabase. Verify row counts.

### Deliverables
- All 18 PG tables created and populated
- All 12 PG views created
- Verification queries return expected row counts

### Steps
Run in order in Supabase SQL Editor:
1. `sql/postgres/01_lookups.sql` (5 tables, ~80 rows)
2. `sql/postgres/02_master_tables.sql` (5 tables, ~90 rows)
3. `sql/postgres/03_transactional_data.sql` (8 tables, ~75K rows)
4. `sql/postgres/04_views.sql` (12 views)

### Verification
```sql
-- In PostgreSQL
SELECT 'Tables: ' || COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- Expected: Tables: 18

SELECT 'Views: ' || COUNT(*) FROM information_schema.views
WHERE table_schema = 'public' AND table_name LIKE 'vw_%';
-- Expected: Views: 12

SELECT (SELECT COUNT(*) FROM patients) AS patients,
       (SELECT COUNT(*) FROM encounters) AS encounters,
       (SELECT COUNT(*) FROM encounter_diagnoses) AS diagnoses;
-- Expected: 5000, 20000, 20000
```

### Common Mistakes
- **Running scripts out of order** — script 3 depends on lookups from script 1; it will fail with FK errors if run first
- **Supabase SQL editor timeout** — script 3 with `generate_series` for 20K encounters can take 30+ seconds. Don't cancel.
- **Mixed-case table names** — PostgreSQL folds unquoted identifiers to lowercase. Always reference tables in lowercase

### Exercise
Write a query that returns the top 10 most common chief complaints from the `encounters` table.

---

## Day 7 — MySQL Source Population

**Objective:** Load all 3 MySQL SQL files into Aiven. Understand the numbers_helper pattern.

### Deliverables
- All 12 MySQL tables created and populated
- All 13 MySQL views created
- `numbers_helper` table with 100,000 rows

### Steps
Run in order in Aiven SQL Editor:
1. `sql/mysql/01_reference_tables.sql` (5 tables, ~90 rows)
2. `sql/mysql/02_transactional_tables.sql` (7 tables + numbers_helper, ~209K rows)
3. `sql/mysql/03_views.sql` (13 views)

### Verification
```sql
USE HealthCare_THP;

SELECT 'Tables: ' || COUNT(*) FROM information_schema.tables
WHERE table_schema = 'HealthCare_THP' AND table_type = 'BASE TABLE';
-- Expected: Tables: 13 (12 + numbers_helper)

SELECT (SELECT COUNT(*) FROM claims)             AS claims,
       (SELECT COUNT(*) FROM claim_lines)        AS claim_lines,
       (SELECT COUNT(*) FROM payments)           AS payments;
-- Expected: 30000, ~45000, ~15000
```

### Common Mistakes
- **Database name wrong case** — `HealthCare_THP` is case-sensitive in Aiven. `healthcare_thp` won't work.
- **Stored procedures attempted** — if you tried to use stored procedures with `DELIMITER` instead of numbers_helper, they fail in Aiven SQL editor. Stick with the script as provided.
- **Recursive CTE attempted** — same issue: `WITH RECURSIVE` hits MySQL's recursion limit (1000) before generating 30K rows. Numbers helper is the only portable way.

### Exercise
Why is the numbers_helper pattern faster than recursive CTE for generating 100K rows? Run `EXPLAIN` on both approaches and compare.

---

## Day 8 — Python Loader Walkthrough

**Objective:** Read the Python loader source code line by line. Understand each function.

### Deliverables
- `scripts/load_sources.py` reviewed and annotated
- 3 questions about the loader answered

### Steps
1. Open `scripts/load_sources.py` in VS Code
2. Read top to bottom; for each function, note:
   - What it returns
   - What environment variables it needs
   - What error handling exists
3. Run a partial load: comment out `mysql_total = ...` line and run only PG load. Then reverse and run only MySQL.

### Questions to Answer
1. Why does the loader uppercase column names before writing to Snowflake?
2. What does `if_exists='replace'` do? When would `if_exists='append'` be more appropriate?
3. What's `chunksize=10000` for? What happens if you remove it?

### Common Mistakes
- **Loader runs but no rows in Snowflake** — usually means HEALTHCARE_DW database doesn't exist yet. Check Snowflake first.
- **`Permission denied`** — Snowflake user doesn't have INSERT on RAW schema. Re-run `00_setup.sql` to fix grants.
- **`pymysql.OperationalError: Can't connect`** — Aiven SSL setting wrong. Make sure `connect_args={'ssl': {'ssl_disabled': False}}`.

### Exercise
Modify the loader to skip a specific table. Hint: change the `PG_TABLES` or `MYSQL_TABLES` list and observe what happens.

---

## Day 9 — Run Full Loader + Verify

**Objective:** Execute the full Python loader. Confirm all 30 source tables land in Snowflake RAW.

### Deliverables
- Loader executed end-to-end successfully
- All 30 tables visible in `HEALTHCARE_DW.RAW`
- Total ~311K rows verified

### Steps
```powershell
cd C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt
dbt_env\Scripts\activate
python scripts\load_sources.py
```

Should run for 3-5 minutes and print:
```
PostgreSQL rows loaded: 102,178
MySQL rows loaded:      209,000
Total rows in RAW:      311,178
```

### Verification
In Snowflake:
```sql
SELECT COUNT(*) AS table_count
FROM HEALTHCARE_DW.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW';
-- Expected: 30

SELECT TABLE_NAME, ROW_COUNT
FROM HEALTHCARE_DW.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW'
ORDER BY ROW_COUNT DESC;
```

### Common Mistakes
- **Some tables empty** — check loader output for "FAILED" entries. Usually a column-name mismatch or NULL handling issue
- **Connection drops mid-load** — Snowflake auto-suspend may kick in if WH was idle. Re-run; it's idempotent.
- **`UnicodeEncodeError`** — pandas tried to write unicode that Snowflake VARCHAR rejected. Add `encoding='utf-8'` to read_sql_table.

---

## Day 10 — Source Exploration + Week 2 Quiz

**Objective:** Spend the day querying RAW data. Take Week 2 mini-quiz.

### Deliverables
- 5 ad-hoc analytical queries against RAW (your choice)
- Week 2 mini-quiz answers

### Suggested Queries
```sql
-- 1. Patient distribution by state
SELECT state_code, COUNT(*) AS patient_count
FROM HEALTHCARE_DW.RAW.PG_PATIENTS
GROUP BY state_code ORDER BY patient_count DESC;

-- 2. Most prolific providers
SELECT provider_id, COUNT(*) AS encounters
FROM HEALTHCARE_DW.RAW.PG_ENCOUNTERS
GROUP BY provider_id ORDER BY encounters DESC LIMIT 10;

-- 3. Claim financial summary
SELECT current_status_code,
       COUNT(*) AS claim_count,
       SUM(total_charge_amount) AS billed,
       SUM(total_paid_amount) AS paid
FROM HEALTHCARE_DW.RAW.MYSQL_CLAIMS
GROUP BY current_status_code;
```

### Week 2 Mini-Quiz

1. Why does the Python loader uppercase column names? What would happen if it didn't?
2. What's the difference between ELT and ETL? Which one does our pipeline use?
3. The loader uses `if_exists='replace'`. What would change if you used `if_exists='append'` instead?
4. Why is the numbers_helper pattern preferred over recursive CTEs for bulk MySQL data generation?
5. If a single source table fails to load, does the rest of the pipeline continue or abort? Where in the code does this behavior come from?

---

# Week 3 — dbt Modeling

## Day 11 — Staging Layer (PostgreSQL)

**Objective:** Build all 18 PG staging models. Understand the staging pattern.

### Deliverables
- 18 `stg_pg_*.sql` model files in `models/staging/postgres/`
- `_pg_sources.yml` declaring all source tables
- `dbt run --select staging.postgres` returns PASS=18

### Steps
1. Create `models/staging/postgres/` folder
2. For each PG source table, create a staging model following the pattern in `02_PROJECT_WALKTHROUGH.md`:
   - source CTE
   - renamed CTE with derived columns
   - final SELECT
3. Add metadata columns via `{{ get_metadata_columns() }}` macro
4. Create `_pg_sources.yml` declaring sources
5. Run `dbt run --select staging.postgres`

### Verification
```sql
SHOW VIEWS IN HEALTHCARE_DW.STAGING;
-- Expected: 18+ views

SELECT bp_classification, COUNT(*)
FROM HEALTHCARE_DW.STAGING.stg_pg_vitals
GROUP BY bp_classification;
-- Expected: 3 categories with rough thirds
```

### Common Mistakes
- **`{{ }}` (Jinja) vs `{ }` (single brace)** — staging models need `{{ config(...) }}` with double braces. Single braces silently fail.
- **BOM characters in files** — if you generate files with PowerShell `Out-File`, you get a UTF-8 BOM that breaks dbt. Use Python to write files instead.
- **Schema not appearing as STAGING** — needs custom `generate_schema_name.sql` macro to override dbt's default prefixing behavior.

### Hints
- Use the Python script `setup_pg_staging.py` from the project's scripts/ folder to generate all 18 files cleanly with proper encoding.
- View compiled SQL at `target/compiled/healthcare_dbt/models/staging/postgres/` to debug.

---

## Day 12 — Staging Layer (MySQL)

**Objective:** Build all 12 MySQL staging models. Run full staging.

### Deliverables
- 12 `stg_mysql_*.sql` model files in `models/staging/mysql/`
- `_mysql_sources.yml` declaring all MySQL sources
- `dbt run --select staging` returns PASS=30 (18 PG + 12 MySQL)

### Verification
```sql
SHOW VIEWS IN HEALTHCARE_DW.STAGING;
-- Expected: 30 views

SELECT current_status_code, COUNT(*)
FROM HEALTHCARE_DW.STAGING.stg_mysql_claims
GROUP BY current_status_code
ORDER BY 2 DESC;
-- Expected distribution: PAID > PARTIAL > DENIED > PENDING
```

### Common Mistakes
- **YAML version typo** — first line of `_mysql_sources.yml` must be `version: 2` (not `ersion: 2` if first character got eaten by tool)
- **`loaded_at_field` warning** — newer dbt wants this nested under `config:` block. The warning is harmless for now.

### Exercise
Add a derived column `is_high_value_claim` to `stg_mysql_claims` that flags claims with `total_charge_amount > 1000`. Run dbt and verify.

---

## Day 13 — Intermediate Layer

**Objective:** Build 8 intermediate models. Understand the bridge model `int_encounter_with_claim`.

### Deliverables
- 8 `int_*.sql` files in `models/intermediate/`
- `dbt run --select intermediate` returns PASS=8

### Steps
1. Create `models/intermediate/` folder
2. Build models in dependency order:
   - `int_patient_demographics`
   - `int_provider_with_facility`
   - `int_encounter_full`
   - `int_chronic_patients`
   - `int_claim_with_provider`
   - `int_claim_financials`
   - `int_payment_reconciliation`
   - `int_encounter_with_claim` (the bridge)
3. Run incrementally: `dbt run --select int_patient_demographics` first, fix any issues, then add more

### Verification
```sql
-- The bridge query - clinical AND financial together
SELECT collection_status, COUNT(*) AS encounters,
       AVG(total_billed) AS avg_billed,
       AVG(total_collected) AS avg_collected
FROM HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
GROUP BY collection_status;
```

### Common Mistakes
- **`listagg` with DISTINCT and ORDER BY** — Snowflake doesn't allow `WITHIN GROUP (ORDER BY ...)` when using DISTINCT. Remove the WITHIN GROUP clause.
- **Missing aggregation** — when joining child tables (e.g., diagnoses to encounters), you must aggregate to encounter grain first. Otherwise duplicates explode the row count.

### Why This Matters
This is the layer where clinical and financial domains finally connect. Read `int_encounter_with_claim.sql` carefully - it's the most important model in the project.

---

## Day 14 — Mart Layer (Star Schema)

**Objective:** Build 7 dimensions and 3 fact tables. Understand star schema design.

### Deliverables
- 7 `dim_*.sql` files in `models/marts/clinical/` and `models/marts/financial/`
- 3 `fct_*.sql` files in same folders
- `dbt run --select marts` returns PASS=10
- All marts materialized as TABLES (not views)

### Verification
```sql
-- Verify physical tables exist
SHOW TABLES IN HEALTHCARE_DW.MART;
-- Expected: 10 TABLE objects (not VIEWs)

-- Quick analytics test
SELECT p.region, p.chronic_category, COUNT(*) AS patients
FROM HEALTHCARE_DW.MART.dim_patient p
GROUP BY p.region, p.chronic_category
ORDER BY p.region, patients DESC;
```

### Common Mistakes
- **Forgetting `materialized='table'`** — defaults to view. Marts MUST be tables for BI performance.
- **`dim_date` requires dbt_utils** — make sure `packages.yml` has `dbt-labs/dbt_utils` and you ran `dbt deps`.
- **Surrogate key naming inconsistency** — fact table FKs must match dim PK names exactly. `patient_key` everywhere, not mix of `patient_id` and `patient_key`.

### Star Schema Quiz
- What's a degenerate dimension? Find one in `fct_claim`.
- Why are dimensions denormalized (single row per entity) instead of normalized?
- What's the difference between a fact table's measures and its categorical attributes?

---

## Day 15 — Full Pipeline Run + Week 3 Quiz

**Objective:** Run the entire pipeline end-to-end. Take Week 3 mini-quiz.

### Deliverables
- `dbt run` returns PASS=48
- 5 ad-hoc analytical queries answered against MART tables
- Week 3 mini-quiz answers

### Steps
```powershell
# Refresh sources
python scripts\load_sources.py

# Build everything
dbt run

# Verify
dbt list --select state:modified+ --output json | wc -l
```

### Suggested Analytics Queries
```sql
-- 1. Top revenue providers
SELECT p.provider_name, SUM(c.total_paid_amount) AS revenue
FROM HEALTHCARE_DW.MART.fct_claim c
JOIN HEALTHCARE_DW.MART.dim_provider p ON c.provider_key = p.provider_key
GROUP BY 1 ORDER BY revenue DESC LIMIT 10;

-- 2. Aging by carrier
SELECT pay.carrier_name, c.aging_bucket, COUNT(*), SUM(c.outstanding_balance)
FROM HEALTHCARE_DW.MART.fct_claim c
JOIN HEALTHCARE_DW.MART.dim_payer pay ON c.payer_key = pay.payer_key
GROUP BY 1, 2 ORDER BY 1, 2;

-- 3. Encounter to payment funnel
SELECT collection_status, COUNT(*) AS encounters,
       SUM(total_billed) AS billed, SUM(total_collected) AS collected
FROM HEALTHCARE_DW.MART.fct_encounter
GROUP BY collection_status;
```

### Week 3 Mini-Quiz

1. What's the difference between staging, intermediate, and mart layers? When does each materialize as a view vs table?
2. Name 3 reasons mart tables are materialized as physical tables instead of views.
3. What does `{{ ref('stg_pg_patients') }}` resolve to at compile time?
4. Why is `int_encounter_with_claim` called the "bridge"? What two domains does it bridge?
5. In a star schema, what's a degenerate dimension? Give an example from this project.

---

# Week 4 — Testing & Documentation

## Day 16 — Schema Tests (not_null, unique, accepted_values)

**Objective:** Add tests to staging models. Understand the four built-in test types.

### Deliverables
- `_pg_staging_tests.yml` with tests for all 18 PG staging models
- `_mysql_staging_tests.yml` with tests for all 12 MySQL staging models
- `dbt test --select staging` returns ~50 passing tests

### Test Types Covered
- `not_null` — column has no NULLs
- `unique` — no duplicate values
- `accepted_values` — column only contains specified enum values
- `relationships` — FK exists in parent table

### Common Mistakes
- **Testing only PKs** — every column with semantic constraints should be tested. Boolean columns, status fields, date fields all need tests.
- **`accepted_values` typo** — must match exactly. Trailing whitespace breaks tests.
- **Test fails but model passes** — tests are separate from models. A test failure means the data violates a rule even though the SQL ran fine.

### Exercise
Add a `not_null` test to `stg_pg_patients.email`. Run tests. Did it pass? Why or why not? (Hint: check the source data)

---

## Day 17 — Custom Tests (dbt_utils.expression_is_true)

**Objective:** Write business-rule tests using `dbt_utils.expression_is_true`.

### Deliverables
- 3 custom expression tests added (your choice)
- All tests passing

### Examples
```yaml
- name: total_charge_amount
  data_tests:
    - dbt_utils.expression_is_true:
        expression: ">= 0"

- name: payment_ratio_pct
  data_tests:
    - dbt_utils.expression_is_true:
        expression: ">= 0 and payment_ratio_pct <= 100"
```

### Exercises
Add tests for:
1. `dim_patient.age >= 0 AND age <= 120` (sanity check)
2. `fct_claim.total_paid_amount <= total_charge_amount` (can't pay more than billed)
3. `dim_provider.tenure_years >= 0` (sanity check)

---

## Day 18 — Test Failures + Debugging

**Objective:** Intentionally break a test. Debug and fix it.

### Deliverables
- A scenario where one test fails
- Steps documented to identify root cause
- Fix applied

### Suggested Exercise
1. Manually update one row in `MYSQL_CLAIMS` to set `total_paid_amount` to a negative number
2. Run `dbt test --select fct_claim`
3. The expression test should fail
4. Find the failing rows: `SELECT * FROM <test result location>`
5. Fix the source data (revert the negative number)
6. Re-run tests; should pass

### Common Mistakes
- **Test result location confusion** — failures are stored in `target/run/.../tests/` directory. Easier to query the failing rows directly with the test SQL from `target/compiled/`.
- **Skipping `dbt run` before `dbt test`** — tests run against the materialized models, not the source SQL. If you change a model and skip `dbt run`, tests run against the OLD version.

---

## Day 19 — Documentation Generation

**Objective:** Document every model. Generate the docs site.

### Deliverables
- Every model has a description (in YAML)
- Every key column has a description
- `dbt docs generate` succeeds
- `dbt docs serve` opens an interactive site at http://localhost:8080
- Lineage graph viewable

### YAML Documentation Pattern
```yaml
- name: dim_patient
  description: |
    Patient master dimension. One row per patient with full demographic,
    geographic, and chronic condition flags. Updated daily via dbt run.
  columns:
    - name: patient_key
      description: "Surrogate primary key — links to fct_encounter and fct_claim"
    - name: chronic_category
      description: |
        Categorization of patient by chronic burden:
          'Healthy' = 0 chronic conditions
          'Single Chronic' = 1 chronic condition
          'Multi-Chronic' = 2-3 chronic conditions
          'High Complexity' = 4+ chronic conditions
```

### Verification
1. Open http://localhost:8080
2. Click `dim_patient` in left tree
3. Should see your description
4. Click lineage icon — should see all upstream/downstream models

### Common Mistakes
- **Block scalars** — multi-line descriptions need `|` (preserves newlines) or `>` (folds to single line). Don't mix indentation.
- **Stale docs** — `dbt docs generate` must run after every model change. Add it to your local pre-push git hook.

---

## Day 20 — Documentation Polish + Week 4 Quiz

**Objective:** Document the remaining models. Take Week 4 quiz.

### Deliverables
- All 48 models documented
- `target/manifest.json` and `target/catalog.json` regenerated
- Week 4 mini-quiz answers

### Week 4 Mini-Quiz

1. What's the difference between a `not_null` test and a `relationships` test? When does each fail?
2. If `dbt test --select dim_patient` fails, where do you find the actual failing rows?
3. What's the purpose of `manifest.json`? `catalog.json`?
4. How does `dbt docs serve` know what models exist? Does it query Snowflake?
5. If you change a column name in a staging model, what other places must you update? List all of them.

---

# Week 5 — Analytics & Capstone

## Days 21-24 — Daily Scenario Queries

Each day, work through a set of business questions in `06_DAILY_SCENARIO_QUERIES.sql`. The file is structured as 5 themed sections; each day covers one section.

### Day 21 — Patient Analytics
Open `06_DAILY_SCENARIO_QUERIES.sql` and work through the **Patient Analytics** section. Answer all queries; verify your results against given expected outputs.

### Day 22 — Provider Productivity
Work through the **Provider & Encounter Analytics** section.

### Day 23 — Claim Financial Performance
Work through the **Claim Financial Performance** section.

### Day 24 — Payer & AR Aging Analytics
Work through the **Payer Analytics** and **AR & Aging** sections.

---

## Day 25 — Capstone Project

**Objective:** Demonstrate end-to-end mastery by extending the warehouse with a new feature.

### Choose ONE Capstone Project

### Option A — Add a Pharmacy Claims Source
Add a third source database tracking pharmacy claims. Tasks:
1. Create a new MySQL or PostgreSQL database with `pharmacy_claims`, `pharmacy_payments`, `drug_codes` tables
2. Generate ~10K pharmacy claim rows
3. Add to Python loader
4. Build `stg_pharmacy_*` staging models
5. Build `int_pharmacy_claim_with_drug` intermediate
6. Build `fct_pharmacy_claim` mart fact
7. Update tests and docs

### Option B — Implement Slowly Changing Dimensions (SCD Type 2)
Track historical changes to `dim_patient` so you can answer "what was this patient's chronic_category 6 months ago?". Tasks:
1. Use dbt snapshots: create `snapshots/dim_patient_snapshot.sql`
2. Run `dbt snapshot` daily; verify history accumulates
3. Create `dim_patient_history` with `valid_from` and `valid_to` columns
4. Update `fct_encounter` to join based on encounter_date (point-in-time)
5. Add tests asserting only one current version exists per patient

### Option C — Build a Reporting Layer
Add a `reporting` schema with pre-aggregated daily/monthly cubes for BI tools. Tasks:
1. Create `models/reporting/` folder
2. Build `rpt_daily_provider_metrics` (one row per provider per day)
3. Build `rpt_monthly_carrier_collection` (one row per carrier per month)
4. Build `rpt_patient_360` (one row per patient with all KPIs joined)
5. All materialized as `incremental` to test that pattern
6. Add scheduling notes in README

### Deliverables
- Working code on a feature branch in your fork
- Pull request with clear description
- All tests passing
- Updated documentation
- 2-page write-up: design choices, trade-offs, future improvements

### Final Grading Rubric
- **Code quality**: Follows existing patterns, well commented (20%)
- **Testing**: New models have appropriate tests (20%)
- **Documentation**: All new models documented in YAML (20%)
- **Functionality**: Builds without errors, queries return expected results (20%)
- **Design rationale**: Write-up explains why, not just what (20%)

---

## Final Week 5 Quiz

1. What does `dbt snapshot` do that `dbt run` doesn't?
2. When would you use `materialized='incremental'` vs `materialized='table'`?
3. If a fact table has 100M rows and rebuilds daily, what's the impact on Snowflake credits? How would you mitigate?
4. Explain the trade-off between fully-denormalized fact tables (your fact has all dim columns inline) vs. surrogate-key joins.
5. What's the role of the `manifest.json` file in CI/CD pipelines?

---

# Beyond Day 25

Topics for continued learning:

- **Incremental models** — `materialized='incremental'` with `unique_key` and `merge` strategy
- **dbt snapshots** — SCD Type 2 history tracking
- **dbt seeds** — versioning small CSV reference data
- **Custom macros** — reusable Jinja for complex logic
- **dbt Cloud / Airflow** — production scheduling
- **Snowflake performance tuning** — clustering keys, partitioning, materialized views
- **Data contracts** — strict schemas to prevent breaking changes
- **dbt Mesh** — splitting large projects across multiple dbt projects
- **Real PHI compliance** — HIPAA, encryption at rest, access logs, BAA review

---

## Related Documents

- `01_ARCHITECTURE.md` — system design context for all training
- `02_PROJECT_WALKTHROUGH.md` — read this in Week 1 alongside Day 4 setup
- `03_DATA_LINEAGE.md` — reference during Weeks 3 and 4
- `05_EXECUTION_LOG_AND_TROUBLESHOOTING.md` — quiz answers and full bug list
- `06_DAILY_SCENARIO_QUERIES.sql` — Week 5 daily exercises
