# 07 — Trainee Assignment Specs

> **For trainees:** This is your assignment book. For each dbt model, you'll find what to build, the inputs, the expected outputs, and verification queries. **No solution code is provided** — that's the point. Build it yourself, run it, verify it works.
>
> **For trainers:** Hand this to trainees on Day 11. The reference solutions exist (in `dbt_models/`) but should NOT be shared until after a trainee submits their attempt for review.

---

## How to Use This Document

Each assignment has the same structure:

- **Model name** — what you'll create
- **Layer + materialization** — staging/intermediate/mart, view/table
- **Grain** — what one row represents
- **Inputs** — what you'll read from
- **Required transformations** — column renames, derivations, joins
- **Output columns** — what your model must produce
- **Verification query** — run this in Snowflake to confirm it worked

### Workflow per model

```
1. Read the spec
2. Open the source table in Snowflake — explore the columns
3. Sketch the SQL on paper (no IDE yet)
4. Create the .sql file in your dbt project
5. Run: dbt compile --select <model>
6. Read target/compiled/.../<model>.sql to check Jinja resolved
7. Run: dbt run --select <model>
8. Run the verification query in Snowflake
9. If green, submit for review
10. If not, debug; check 05_EXECUTION_LOG_AND_TROUBLESHOOTING.md
```

---

## Assignment Pack 1 — Macros (Day 10 setup)

Before any model assignments, you must build two reusable macros.

### Assignment 1.1: `generate_schema_name` macro

**File location:** `macros/generate_schema_name.sql`

**Why this exists:** dbt's default behavior prefixes custom schemas with the target schema. We need literal schema names (STAGING, MART, etc.) without prefixes.

**Required behavior:**
- If `custom_schema_name` is `none`, return `target.schema`
- Otherwise, return `custom_schema_name` trimmed and uppercased

**Test it works:** After creating, run `dbt run --select stg_pg_patients` (after building the staging model). Verify the view is created in `STAGING` schema, NOT `RAW_STAGING`.

---

### Assignment 1.2: `get_metadata_columns` macro

**File location:** `macros/get_metadata_columns.sql`

**Why this exists:** Every staging model adds the same 3 metadata columns. Instead of repeating, build it once.

**Required output (when called):**
- `current_timestamp() as _dbt_loaded_at`
- The dbt invocation_id wrapped as `_dbt_run_id`
- The current model's name as `_dbt_source_model`

**Hints:**
- Use `{{ invocation_id }}` to get the run ID
- Use `{{ this.name }}` to get the model name
- Wrap them as string literals

**Test it works:** After using in `stg_pg_patients`, query:
```sql
SELECT _dbt_loaded_at, _dbt_run_id, _dbt_source_model
FROM HEALTHCARE_DW.STAGING.STG_PG_PATIENTS LIMIT 5;
```
You should see a timestamp, a UUID-like string, and `'stg_pg_patients'`.

---

# Assignment Pack 2 — PostgreSQL Staging (Day 11)

## Common rules for ALL staging models

Every staging model in this pack follows the same skeleton:

```sql
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', '<table_name>') }}
),

renamed as (
    select
        ...your columns here...,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
```

You write the `renamed` CTE based on each assignment's transformation rules.

---

### Assignment 2.1: `stg_pg_patients` ⭐ START HERE

**Source:** `pg_clinical.pg_patients`
**Target:** `HEALTHCARE_DW.STAGING.stg_pg_patients`
**Grain:** One row per patient

**Required transformations:**
- Rename `mrn` → `medical_record_number`
- Add derived column `full_name` (concatenate first_name + space + last_name)
- Add derived column `age` (years between `date_of_birth` and current date)
- Keep all other columns as-is
- Add metadata columns via the macro

**Verification:**
```sql
SELECT COUNT(*) FROM HEALTHCARE_DW.STAGING.stg_pg_patients;
-- Expected: 5000

SELECT medical_record_number, full_name, age, gender
FROM HEALTHCARE_DW.STAGING.stg_pg_patients
LIMIT 10;
-- Should see clean MRN format (MRN0000001), names, ages 1-80, M/F/O
```

---

### Assignment 2.2: `stg_pg_providers`

**Source:** `pg_clinical.pg_providers`
**Grain:** One row per provider

**Required transformations:**
- Add `full_name` (first + last)
- Add `tenure_years` (years between `hire_date` and current date)
- Keep other columns

**Verification:**
```sql
SELECT COUNT(*) FROM HEALTHCARE_DW.STAGING.stg_pg_providers;
-- Expected: 50

SELECT provider_id, full_name, tenure_years FROM HEALTHCARE_DW.STAGING.stg_pg_providers ORDER BY tenure_years DESC LIMIT 5;
-- Tenures should range roughly 7-19 years
```

---

### Assignment 2.3: `stg_pg_facilities`

**Source:** `pg_clinical.pg_facilities`
**Grain:** One row per facility

**Required transformations:**
- Rename `type_id` → `facility_type_id` (clearer name)
- Keep other columns

**Verification:**
```sql
SELECT facility_id, facility_name, capacity_beds FROM HEALTHCARE_DW.STAGING.stg_pg_facilities ORDER BY capacity_beds DESC;
-- Should see 20 facilities with bed counts ranging 0-450
```

---

### Assignment 2.4: `stg_pg_facility_types`

**Source:** `pg_clinical.pg_facility_types`
**Grain:** One row per facility type (lookup)

**Required transformations:**
- Rename `type_id` → `facility_type_id`
- Rename `type_name` → `facility_type_name`
- Rename `description` → `facility_type_description`

**Verification:**
```sql
SELECT * FROM HEALTHCARE_DW.STAGING.stg_pg_facility_types;
-- Expected: 7 rows
```

---

### Assignment 2.5: `stg_pg_specialty_types`

**Source:** `pg_clinical.pg_specialty_types`
**Grain:** One row per specialty (lookup)

**Required transformations:**
- Rename `description` → `specialty_description`
- Keep `specialty_id` and `specialty_name`

---

### Assignment 2.6: `stg_pg_states`

**Source:** `pg_clinical.pg_states`
**Grain:** One row per state (lookup)

**Required transformations:** None — straight copy with metadata columns

---

### Assignment 2.7: `stg_pg_icd10_codes`

**Source:** `pg_clinical.pg_icd10_codes`
**Grain:** One row per ICD-10 code

**Required transformations:**
- Rename `code` → `icd10_code` (more descriptive)
- Rename `description` → `diagnosis_description`
- Rename `category` → `disease_category`
- Keep `is_chronic` flag

---

### Assignment 2.8: `stg_pg_cpt_codes`

**Source:** `pg_clinical.pg_cpt_codes`
**Grain:** One row per CPT code

**Required transformations:**
- Rename `code` → `cpt_code`
- Rename `description` → `procedure_description`
- Rename `category` → `procedure_category`

---

### Assignment 2.9: `stg_pg_insurance_carriers`

**Source:** `pg_clinical.pg_insurance_carriers`

**Required transformations:**
- Rename `payer_id` → `external_payer_id` (avoid naming collision later)
- Rename `contract_start` → `contract_start_date`

---

### Assignment 2.10: `stg_pg_employees`

**Source:** `pg_clinical.pg_employees`

**Required transformations:**
- Add `full_name` (first + last)

---

### Assignment 2.11: `stg_pg_encounters` ⭐ KEY MODEL

**Source:** `pg_clinical.pg_encounters`
**Grain:** One row per patient encounter (visit)

**Required transformations:**
- Rename `status` → `encounter_status`
- Add derived boolean column `is_acute_visit`:
  - TRUE if `encounter_type` is `'Emergency'` OR `'Urgent Care'`
  - FALSE otherwise

**Verification:**
```sql
SELECT COUNT(*) FROM HEALTHCARE_DW.STAGING.stg_pg_encounters;
-- Expected: 20000

SELECT encounter_type, is_acute_visit, COUNT(*)
FROM HEALTHCARE_DW.STAGING.stg_pg_encounters
GROUP BY 1, 2 ORDER BY 1;
-- Emergency and Urgent Care should show is_acute_visit = TRUE
-- Others should show is_acute_visit = FALSE
```

---

### Assignment 2.12: `stg_pg_encounter_diagnoses`

**Source:** `pg_clinical.pg_encounter_diagnoses`

**Required transformations:**
- Rename `notes` → `diagnosis_notes` (avoid generic name)

---

### Assignment 2.13: `stg_pg_encounter_procedures`

**Source:** `pg_clinical.pg_encounter_procedures`

**Required transformations:**
- Rename `performed_by` → `performed_by_provider_id` (clearer)
- Rename `notes` → `procedure_notes`

---

### Assignment 2.14: `stg_pg_prescriptions`

**Source:** `pg_clinical.pg_prescriptions`

**Required transformations:** None — straight copy with metadata

---

### Assignment 2.15: `stg_pg_lab_orders`

**Source:** `pg_clinical.pg_lab_orders`

**Required transformations:**
- Rename `status` → `order_status`

---

### Assignment 2.16: `stg_pg_lab_results`

**Source:** `pg_clinical.pg_lab_results`

**Required transformations:**
- Rename `notes` → `result_notes`

---

### Assignment 2.17: `stg_pg_vitals` ⭐ KEY DERIVED COLUMN

**Source:** `pg_clinical.pg_vitals`
**Grain:** One row per vitals measurement

**Required transformations:**
- Add derived column `bp_classification` (American Heart Association rules):
  - `'Hypertensive'` when `systolic_bp >= 140` OR `diastolic_bp >= 90`
  - `'Elevated'` when `systolic_bp >= 120` OR `diastolic_bp >= 80` (and not Hypertensive)
  - `'Normal'` otherwise

**Hint:** Use a CASE statement. The order of WHEN conditions matters.

**Verification:**
```sql
SELECT bp_classification, COUNT(*)
FROM HEALTHCARE_DW.STAGING.stg_pg_vitals
GROUP BY bp_classification
ORDER BY 2 DESC;
-- Should see roughly thirds across Normal/Elevated/Hypertensive
```

---

### Assignment 2.18: `stg_pg_allergies`

**Source:** `pg_clinical.pg_allergies`

**Required transformations:** None — straight copy with metadata

---

## Day 11 Final Verification

After completing all 18 PG staging models:

```powershell
dbt run --select staging.postgres
```

Expected: `Done. PASS=18 WARN=0 ERROR=0 SKIP=0 TOTAL=18`

```sql
SELECT COUNT(*) AS view_count
FROM HEALTHCARE_DW.INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'STAGING' AND TABLE_NAME LIKE 'STG_PG_%';
-- Expected: 18
```

---

# Assignment Pack 3 — MySQL Staging (Day 12)

Same skeleton as PG staging models, but using `{{ source('mysql_claims', '...') }}`.

### Assignment 3.1: `stg_mysql_payer_types`

**Source:** `mysql_claims.mysql_payer_types`

**Required transformations:**
- Rename `type_code` → `payer_type_code`
- Rename `type_name` → `payer_type_name`
- Rename `description` → `payer_type_description`

---

### Assignment 3.2: `stg_mysql_insurance_plans` ⭐ KEY DERIVED COLUMN

**Source:** `mysql_claims.mysql_insurance_plans`
**Grain:** One row per plan

**Required transformations:**
- Add derived column `deductible_tier`:
  - `'No Deductible'` when `deductible_amount = 0`
  - `'Low Deductible'` when `deductible_amount <= 1000`
  - `'Medium Deductible'` when `deductible_amount <= 3000`
  - `'High Deductible'` otherwise

**Verification:**
```sql
SELECT deductible_tier, COUNT(*)
FROM HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
GROUP BY 1;
```

---

### Assignment 3.3: `stg_mysql_billing_codes`

**Source:** `mysql_claims.mysql_billing_codes`

**Required transformations:**
- Rename `code` → `billing_code`
- Rename `description` → `code_description`

---

### Assignment 3.4: `stg_mysql_claim_status_codes`

**Source:** `mysql_claims.mysql_claim_status_codes`

**Required transformations:**
- Rename `description` → `status_description`

---

### Assignment 3.5: `stg_mysql_adjustment_codes`

**Source:** `mysql_claims.mysql_adjustment_codes`

**Required transformations:**
- Rename `code` → `adjustment_code`
- Rename `description` → `adjustment_description`
- Rename `category` → `adjustment_category`

---

### Assignment 3.6: `stg_mysql_claims` ⭐⭐ THE BIGGEST STAGING MODEL

**Source:** `mysql_claims.mysql_claims`
**Grain:** One row per claim

**Required transformations:**
- Rename `patient_mrn` → `medical_record_number`
- Add derived `days_to_submit` = days between `service_date` and `submission_date`
- Add derived `outstanding_balance` = `total_charge_amount - total_paid_amount`
- Add derived `payment_ratio_pct`:
  - `0` when `total_charge_amount = 0` (avoid divide-by-zero)
  - Otherwise round `(total_paid_amount / total_charge_amount) * 100` to 2 decimals

**Hint:** Use Snowflake's `datediff('day', start, end)` function.

**Verification:**
```sql
SELECT COUNT(*) FROM HEALTHCARE_DW.STAGING.stg_mysql_claims;
-- Expected: 30000

SELECT claim_number, total_charge_amount, total_paid_amount, outstanding_balance, payment_ratio_pct
FROM HEALTHCARE_DW.STAGING.stg_mysql_claims
WHERE current_status_code = 'PAID' LIMIT 10;
-- Verify outstanding_balance = charge - paid
-- Verify payment_ratio_pct is reasonable (60-95% for paid claims)
```

---

### Assignment 3.7: `stg_mysql_claim_lines`

**Source:** `mysql_claims.mysql_claim_lines`

**Required transformations:**
- Rename `status_code` → `line_status_code`

---

### Assignment 3.8: `stg_mysql_payments` ⭐ KEY DERIVED COLUMN

**Source:** `mysql_claims.mysql_payments`
**Grain:** One row per payment

**Required transformations:**
- Add derived `days_to_post`:
  - `NULL` when `posted_date IS NULL` (not yet posted)
  - Otherwise `datediff('day', payment_date, posted_date)`

**Verification:**
```sql
SELECT
  COUNT(*) AS total_payments,
  COUNT(days_to_post) AS posted_count,
  AVG(days_to_post) AS avg_days_to_post
FROM HEALTHCARE_DW.STAGING.stg_mysql_payments;
```

---

### Assignment 3.9: `stg_mysql_adjustments`

**Source:** `mysql_claims.mysql_adjustments`

**Required transformations:**
- Rename `notes` → `adjustment_notes`

---

### Assignment 3.10: `stg_mysql_remittance_advice`

**Source:** `mysql_claims.mysql_remittance_advice`

**Required transformations:**
- Rename `notes` → `remittance_notes`

---

### Assignment 3.11: `stg_mysql_claim_status_history`

**Source:** `mysql_claims.mysql_claim_status_history`

**Required transformations:**
- Rename `notes` → `status_notes`

---

### Assignment 3.12: `stg_mysql_claim_attachments`

**Source:** `mysql_claims.mysql_claim_attachments`

**Required transformations:**
- Rename `notes` → `attachment_notes`

---

## Day 12 Final Verification

```powershell
dbt run --select staging.mysql
```
Expected: `Done. PASS=12`

```powershell
dbt run --select staging
```
Expected: `Done. PASS=30` (18 PG + 12 MySQL)

---

# Assignment Pack 4 — Intermediate Layer (Day 13)

### Assignment 4.1: `int_patient_demographics`

**Folder:** `models/intermediate/`
**Materialization:** view (default for intermediate)
**Grain:** One row per patient

**Inputs:**
- `stg_pg_patients`
- `stg_pg_states`

**Required logic:**
1. LEFT JOIN patients with states on `state_code` to get `state_name` and `region`
2. Add derived `age_group`:
   - `'Pediatric'` when age < 18
   - `'Young Adult'` when age 18-39
   - `'Adult'` when age 40-64
   - `'Senior'` when age >= 65
3. Add boolean `is_senior` (age >= 65)
4. Add boolean `is_pediatric` (age < 18)

**Verification:**
```sql
SELECT region, age_group, COUNT(*)
FROM HEALTHCARE_DW.INTERMEDIATE.int_patient_demographics
GROUP BY 1, 2 ORDER BY 1, 2;
```

---

### Assignment 4.2: `int_provider_with_facility`

**Inputs:**
- `stg_pg_providers`
- `stg_pg_specialty_types`
- `stg_pg_facilities`
- `stg_pg_facility_types`

**Required logic:**
- 4-way LEFT JOIN to bring in: `specialty_name`, `facility_name`, `facility_type_name`, `facility_city`, `facility_state`
- Rename `first_name` → `provider_first_name`
- Rename `last_name` → `provider_last_name`
- Rename `full_name` → `provider_name`
- Rename `email` → `provider_email`
- Rename `phone` → `provider_phone`

**Verification:**
```sql
SELECT provider_id, provider_name, specialty_name, facility_name
FROM HEALTHCARE_DW.INTERMEDIATE.int_provider_with_facility LIMIT 10;
-- All 4 lookups should populate; no NULLs in joined columns
```

---

### Assignment 4.3: `int_encounter_full`

**Inputs:**
- `stg_pg_encounters`
- `stg_pg_encounter_diagnoses` (must aggregate)
- `stg_pg_encounter_procedures` (must aggregate)

**Required logic:**

Step 1 — Aggregate diagnoses to encounter grain:
- `total_diagnoses` = count of distinct ICD-10 codes per encounter
- `primary_diagnoses` = count where `diagnosis_type = 'Primary'`
- `primary_icd10_code` = MAX value where diagnosis is Primary
- `all_icd10_codes` = pipe-separated LISTAGG of all codes

Step 2 — Aggregate procedures to encounter grain:
- `total_procedures` = distinct CPT codes per encounter
- `total_procedure_charges` = SUM of charges
- `all_cpt_codes` = pipe-separated LISTAGG

Step 3 — LEFT JOIN both back to encounter:
- Use `coalesce(..., 0)` for the count and sum columns to avoid NULLs

**Hint:** This model uses 3 CTEs before the final SELECT.

**Verification:**
```sql
SELECT total_diagnoses, COUNT(*)
FROM HEALTHCARE_DW.INTERMEDIATE.int_encounter_full
GROUP BY 1 ORDER BY 1;
-- Should see most encounters have 1 diagnosis, some have 0 or 2
```

---

### Assignment 4.4: `int_claim_with_provider`

**Inputs:**
- `stg_mysql_claims`
- `int_provider_with_facility` (use this, not the staging — already enriched)
- `stg_mysql_insurance_plans`
- `stg_mysql_claim_status_codes`

**Required logic:**
- 4-way LEFT JOIN to add: `provider_name`, `specialty_name`, `facility_name`, `facility_type_name`, `plan_name`, `plan_type`, `deductible_tier`, `status_name`, `is_terminal`
- Pass through all original claim columns

**Why this pattern:** Avoid repeating these joins in `int_encounter_with_claim` and `fct_claim`. Build once, use twice.

---

### Assignment 4.5: `int_claim_financials` ⭐ COMPLEX AGGREGATIONS

**Inputs:**
- `stg_mysql_claims`
- `stg_mysql_payments`
- `stg_mysql_adjustments`

**Required logic:**

Step 1 — Aggregate payments per claim (filter `is_posted = TRUE`):
- `payment_count`, `total_payment_received`
- `first_payment_date` (MIN), `last_payment_date` (MAX)
- `has_eft_payment` boolean (1 if any EFT payment exists, else 0)
- `has_check_payment` boolean

Step 2 — Aggregate adjustments per claim:
- `adjustment_count`, `total_adjustments`
- `has_medical_necessity_denial` (1 if any code in `('CO-50','CO-167')`)
- `has_coding_issue` (1 if any code in `('CO-4','CO-11','CO-151')`)

Step 3 — Combine into final view + add derived `payment_status_category`:
- `'Fully Denied'` if `total_paid = 0` AND status is `'DENIED'`
- `'Unpaid'` if `total_paid = 0` (and not denied)
- `'Fully Paid'` if `total_paid >= total_charge * 0.95`
- `'Partially Paid'` if `total_paid > 0`
- `'Unknown'` otherwise

**Hint:** Use `coalesce(..., 0)::boolean` to convert int aggregates to booleans cleanly.

---

### Assignment 4.6: `int_encounter_with_claim` ⭐⭐⭐ THE BRIDGE — MOST IMPORTANT MODEL

**This is the most important model in the entire project. Take your time.**

**Inputs:**
- `int_encounter_full` (clinical side, already enriched)
- `int_claim_with_provider` (financial side, already enriched)

**Required logic:**

Step 1 — Roll up claim_aggregates to encounter grain (one encounter can have multiple claims):
- `claims_per_encounter` (COUNT)
- `total_billed` = SUM of charge amounts
- `total_collected` = SUM of paid amounts
- `total_outstanding` = SUM of outstanding balances
- `latest_claim_status` = MAX of status code (loose proxy for "latest")
- `had_clean_claim` = MAX of is_clean_claim boolean

Step 2 — LEFT JOIN encounters to claim_aggregates (preserve encounters with no claim filed)

Step 3 — Use coalesce to default missing values to 0

Step 4 — Add derived `collection_status`:
- `'No Claim Filed'` when `claims_per_encounter IS NULL` (no claim was filed)
- `'Unpaid'` when `total_collected = 0`
- `'Fully Collected'` when `total_collected >= total_billed * 0.95`
- `'Partially Collected'` otherwise

**Why this is the most important model:** It's the FIRST place where clinical (PostgreSQL) and financial (MySQL) data are unified at the same grain. Every "did we get paid for what we did" question goes through this model.

**Verification:**
```sql
SELECT collection_status, COUNT(*),
       SUM(total_billed) AS billed,
       SUM(total_collected) AS collected
FROM HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
GROUP BY collection_status ORDER BY 2 DESC;
```

---

### Assignment 4.7: `int_payment_reconciliation`

**Inputs:**
- `stg_mysql_payments`
- `stg_mysql_remittance_advice`
- `stg_mysql_claims`

**Required logic:**
- LEFT JOIN payments to claims to get `claim_charge` and `claim_allowed`
- LEFT JOIN payments to remittance to get remittance details
- Add `variance_from_charge` = `claim_charge - payment_amount`
- Add `variance_from_allowed` = `claim_allowed - payment_amount`
- Add derived `reconciliation_status`:
  - `'Zero Payment'` when `payment_amount = 0`
  - `'Fully Paid'` when `payment_amount = claim_charge`
  - `'Overpayment'` when `payment_amount > claim_charge`
  - `'Underpaid Significantly'` when `payment_amount < claim_charge * 0.5`
  - `'Partial Payment'` otherwise

---

### Assignment 4.8: `int_chronic_patients` ⭐ TRICKY SNOWFLAKE QUIRK

**Inputs:**
- `stg_pg_encounter_diagnoses`
- `stg_pg_icd10_codes`
- `stg_pg_encounters`

**Required logic:**

Step 1 — Aggregate per patient (join encounters → diagnoses → icd_codes):
- `chronic_condition_count` = count of distinct chronic ICD-10 codes
- `chronic_conditions_list` = LISTAGG DISTINCT of chronic descriptions
- `most_recent_chronic_dx` = MAX of `diagnosed_date`

⚠️ **Snowflake quirk:** When using `listagg(DISTINCT ...)`, you CANNOT add `WITHIN GROUP (ORDER BY <other_column>)`. The list will be unordered. That's OK.

Step 2 — Categorize:
- `chronic_category`:
  - `'Healthy'` if count = 0
  - `'Single Chronic'` if count = 1
  - `'Multi-Chronic'` if count between 2 and 3
  - `'High Complexity'` if count >= 4
- `is_chronic_patient` boolean (TRUE if count >= 2)

**Verification:**
```sql
SELECT chronic_category, COUNT(*) FROM HEALTHCARE_DW.INTERMEDIATE.int_chronic_patients GROUP BY 1;
```

---

## Day 13 Final Verification

```powershell
dbt run --select intermediate
```
Expected: `Done. PASS=8`

---

# Assignment Pack 5 — Mart Layer (Day 14)

**Important:** Mart models materialize as **TABLES**, not views. Use `{{ config(materialized='table') }}` at the top of every mart file.

---

## Dimensions

### Assignment 5.1: `dim_patient`

**Folder:** `models/marts/clinical/`
**Materialization:** TABLE
**Grain:** One row per patient

**Inputs:**
- `int_patient_demographics`
- `int_chronic_patients`

**Required logic:**
- LEFT JOIN demographics to chronic (not all patients have chronic data)
- Surrogate key: `patient_key` (rename from `patient_id`)
- Use `coalesce(c.chronic_condition_count, 0)` to default to 0
- Use `coalesce(c.chronic_category, 'Healthy')` to default
- Use `coalesce(c.is_chronic_patient, false)` to default
- Add `dim_created_at = current_timestamp()` audit column

---

### Assignment 5.2: `dim_provider`

**Inputs:** `int_provider_with_facility`

**Required logic:**
- Surrogate key: `provider_key`
- Add derived `experience_level`:
  - `'Junior'` when tenure < 5 years
  - `'Mid-Level'` when tenure 5-14 years
  - `'Senior'` when tenure >= 15 years

---

### Assignment 5.3: `dim_facility`

**Inputs:**
- `stg_pg_facilities`
- `stg_pg_facility_types`
- `stg_pg_states`

**Required logic:**
- 3-way LEFT JOIN
- Surrogate key: `facility_key`
- Add derived `facility_size`:
  - `'Outpatient Only'` when capacity = 0
  - `'Small'` when capacity < 100
  - `'Medium'` when capacity 100-250
  - `'Large'` otherwise
- Add `years_in_operation` (datediff year from `opened_date`)

---

### Assignment 5.4: `dim_diagnosis`

**Inputs:** `stg_pg_icd10_codes`

**Required logic:**
- Surrogate key: `diagnosis_key` = the ICD-10 code itself
- Add derived `risk_category`:
  - `'High Risk'` for categories Cardiovascular, Endocrine, Respiratory, Renal
  - `'Behavioral'` for Mental, Neurological
  - `'Low Acuity'` for Wellness, Symptoms
  - `'Standard'` for everything else

---

### Assignment 5.5: `dim_procedure`

**Inputs:**
- `stg_pg_cpt_codes` (CPT codes from clinical system)
- `stg_mysql_billing_codes` (CPT + HCPCS from billing system)

**Required logic:**
- FULL OUTER JOIN — include codes from either source
- Surrogate key: `procedure_key` = `coalesce(cpt_code, billing_code)`
- Use `coalesce` for description, category, base_cost
- Add derived `cost_tier`:
  - `'High Cost'` when base > 5000
  - `'Medium Cost'` when base > 500
  - `'Low Cost'` otherwise

---

### Assignment 5.6: `dim_date`

**Inputs:** `dbt_utils.date_spine` macro

**Required logic:**

Step 1 — Build the date spine using `{{ dbt.date_spine(...) }}`:
- `datepart="day"`
- `start_date="cast('2020-01-01' as date)"`
- `end_date="cast('2030-12-31' as date)"`

Step 2 — Compute calendar attributes from `date_day`:
- Surrogate key: `date_key`
- `year`, `quarter`, `month_number`
- `month_name` via `to_char(date_day, 'Mon')`
- `week_of_year`, `day_of_month`, `day_of_week`
- `day_name` via `to_char(date_day, 'Dy')`
- `is_weekend` boolean (day_of_week in 0, 6)
- `quarter_name` ('Q1', 'Q2', 'Q3', 'Q4')
- `year_month` via `to_char(date_day, 'YYYY-MM')`

**Prerequisite:** Make sure `dbt_utils` is in `packages.yml` and you've run `dbt deps`.

**Verification:**
```sql
SELECT COUNT(*) FROM HEALTHCARE_DW.MART.dim_date;
-- Expected: 4018 (10 years of days)
```

---

### Assignment 5.7: `dim_payer`

**Folder:** `models/marts/financial/`
**Inputs:**
- `stg_mysql_insurance_plans`
- `stg_pg_insurance_carriers`
- `stg_mysql_payer_types`

**Required logic:**
- Surrogate key: `payer_key` = `plan_id`
- 3-way LEFT JOIN
- Pull through `carrier_name`, `carrier_type`, `payer_type_name`
- Add derived `payer_segment`:
  - `'Government'` for Medicare or Medicaid
  - `'Patient'` for Self-Pay
  - `'Commercial'` for everything else

---

## Facts

### Assignment 5.8: `fct_encounter`

**Inputs:** `int_encounter_with_claim`

**Required logic:**

A fact table has 4 column types. Build them in this order:

1. **Surrogate key:** `encounter_key` (renamed from `encounter_id`)
2. **Degenerate dimension:** `encounter_number` (no separate dim — lives here)
3. **FK to dimensions:**
   - `patient_key`, `provider_key`, `facility_key`, `date_key` (from encounter_date), `primary_diagnosis_key`
4. **Categorical attributes:** `encounter_type`, `is_acute_visit`, `latest_claim_status`, `had_clean_claim`, `collection_status`
5. **Measures:** `duration_minutes`, `total_diagnoses`, `total_procedures`, `total_procedure_charges`, `claims_per_encounter`, `total_billed`, `total_collected`, `total_outstanding`
6. **Derived measure:** `collection_rate_pct`:
   - `0` when `total_billed = 0`
   - Otherwise `round((total_collected / total_billed) * 100, 2)`
7. **Audit:** `fct_created_at`

---

### Assignment 5.9: `fct_claim` ⭐ CENTRAL FINANCIAL FACT

**Inputs:**
- `int_claim_with_provider`
- `int_claim_financials`

**Required logic:**

LEFT JOIN both inputs on `claim_id`. Then build:

1. **Surrogate key:** `claim_key`
2. **Degenerate dim:** `claim_number`
3. **FKs:** `patient_key`, `provider_key`, `facility_key`, `payer_key` (from `plan_id`), `encounter_key`, `service_date_key`, `submission_date_key`, `primary_diagnosis_key`
4. **Measures:** all the financial amounts plus `payment_count`, `adjustment_count`
5. **Categorical attributes:** all status flags and categorizations
6. **Derived `aging_bucket`** based on days from submission to current date:
   - `'No Balance'` when `outstanding_balance <= 0`
   - `'0-30 days'` when days <= 30
   - `'31-60 days'` when days <= 60
   - `'61-90 days'` when days <= 90
   - `'91-120 days'` when days <= 120
   - `'120+ days'` otherwise
7. **Audit:** `fct_created_at`

**Verification:**
```sql
SELECT aging_bucket, COUNT(*), SUM(outstanding_balance)
FROM HEALTHCARE_DW.MART.fct_claim
GROUP BY 1
ORDER BY CASE aging_bucket
  WHEN 'No Balance' THEN 0
  WHEN '0-30 days' THEN 1
  WHEN '31-60 days' THEN 2
  WHEN '61-90 days' THEN 3
  WHEN '91-120 days' THEN 4
  ELSE 5 END;
```

---

### Assignment 5.10: `fct_payment`

**Inputs:** `int_payment_reconciliation`

**Required logic:**
1. Surrogate key: `payment_key`
2. Degenerate dims: `claim_number`, `payment_number`, `check_number`, `era_number`
3. FKs: `claim_key`, `payment_date_key`, `posted_date_key`
4. Measures: charge, allowed, payment, variance fields, days_to_post
5. Categorical: `payment_method`, `is_posted`, `reconciliation_status`
6. Audit timestamp

---

## Day 14 Final Verification

```powershell
dbt run --select marts
```
Expected: `Done. PASS=10` (all materialized as TABLE)

```sql
SHOW TABLES IN HEALTHCARE_DW.MART;
-- Expected: 10 entries with type=TABLE (not VIEW)
```

---

# Assignment Pack 6 — Tests (Day 16-17)

For each layer, create a test YAML file with at minimum these tests. The exact YAML structure is documented in dbt's official docs.

### Day 16 — Required tests for STAGING layer

For each model, you should at minimum test:

| Model | Required tests |
|---|---|
| `stg_pg_patients` | unique + not_null on `patient_id`; unique + not_null on `medical_record_number`; accepted_values on `gender` (M, F, O); `age` between 0 and 120 |
| `stg_pg_providers` | unique + not_null on `provider_id`; unique + not_null on `npi_number` |
| `stg_pg_encounters` | unique + not_null on `encounter_id`; FK relationship to `stg_pg_patients` and `stg_pg_providers` |
| `stg_pg_facilities` | unique + not_null on `facility_id` |
| `stg_pg_encounter_diagnoses` | unique + not_null on `diagnosis_id`; FK to `stg_pg_encounters` |
| `stg_pg_encounter_procedures` | unique + not_null on `procedure_id`; not_null on `encounter_id` |
| `stg_mysql_claims` | unique + not_null on `claim_id`; unique + not_null on `claim_number`; `total_charge_amount >= 0`; accepted_values on `current_status_code` |
| `stg_mysql_claim_lines` | unique + not_null on `claim_line_id`; FK to `stg_mysql_claims` |
| `stg_mysql_payments` | unique + not_null on `payment_id`; FK to `stg_mysql_claims`; `payment_amount >= 0` |
| `stg_mysql_insurance_plans` | unique + not_null on `plan_id`; unique + not_null on `plan_code`; accepted_values on `deductible_tier` |

### Day 17 — Custom expression tests

Use `dbt_utils.expression_is_true` for business rules:
- `dim_patient.age >= 0 AND age <= 120`
- `fct_claim.total_paid_amount <= total_charge_amount`
- `fct_payment.payment_amount >= 0`

---

# Submission Format

When you finish a model, submit:

1. **The .sql file**
2. **Output of:**
   ```powershell
   dbt run --select <model_name>
   ```
3. **Output of the verification query** from this doc
4. **Anything you found surprising**

Trainer will review against the reference solution and either approve or send back with feedback.

---

# Common Pitfalls — Read Before Starting

1. **`{{ }}` not `{ }`** — Jinja templates need TWO opening AND TWO closing braces. Single brace silently fails.
2. **Materialization defaults** — staging defaults to view, mart should be `{{ config(materialized='table') }}`
3. **`coalesce` after LEFT JOIN** — without it, NULLs from missing rows pollute downstream sums
4. **Snowflake `LISTAGG` + DISTINCT** — cannot have `WITHIN GROUP (ORDER BY ...)` on a different column
5. **Schema name override** — until you build `generate_schema_name.sql`, dbt creates `RAW_STAGING` instead of `STAGING`

If you hit any of these, see `05_EXECUTION_LOG_AND_TROUBLESHOOTING.md`.

---

# Definition of Done — Day 15 Capstone Check

You're done with Weeks 3-4 when:

```powershell
dbt run
# Done. PASS=48 WARN=0 ERROR=0

dbt test
# Done. PASS=80+ WARN=0 ERROR=0

dbt docs generate
dbt docs serve
# Browser opens at localhost:8080 with full lineage graph
```

Submit a screenshot of all three to your trainer.
