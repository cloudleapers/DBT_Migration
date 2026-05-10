"""
Creates schema.yml files for tests and documentation across all model layers.
"""
from pathlib import Path

PROJECT_ROOT = Path(r"C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt")

# ============= STAGING TESTS =============

PG_STAGING_TESTS = """version: 2

models:
  - name: stg_pg_patients
    description: "Cleaned patient master data from PostgreSQL"
    columns:
      - name: patient_id
        description: "Unique patient identifier"
        data_tests:
          - not_null
          - unique
      - name: medical_record_number
        description: "MRN — unique medical record number"
        data_tests:
          - not_null
          - unique
      - name: gender
        data_tests:
          - accepted_values:
              values: ['M', 'F', 'O']
      - name: age
        data_tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0 and age <= 120"

  - name: stg_pg_providers
    description: "Cleaned healthcare provider data"
    columns:
      - name: provider_id
        data_tests:
          - not_null
          - unique
      - name: npi_number
        description: "National Provider Identifier"
        data_tests:
          - not_null
          - unique

  - name: stg_pg_encounters
    description: "Patient encounter/visit records"
    columns:
      - name: encounter_id
        data_tests:
          - not_null
          - unique
      - name: patient_id
        data_tests:
          - not_null
          - relationships:
              to: ref('stg_pg_patients')
              field: patient_id
      - name: provider_id
        data_tests:
          - not_null
          - relationships:
              to: ref('stg_pg_providers')
              field: provider_id

  - name: stg_pg_facilities
    columns:
      - name: facility_id
        data_tests:
          - not_null
          - unique

  - name: stg_pg_encounter_diagnoses
    columns:
      - name: diagnosis_id
        data_tests:
          - not_null
          - unique
      - name: encounter_id
        data_tests:
          - not_null
          - relationships:
              to: ref('stg_pg_encounters')
              field: encounter_id

  - name: stg_pg_encounter_procedures
    columns:
      - name: procedure_id
        data_tests:
          - not_null
          - unique
      - name: encounter_id
        data_tests:
          - not_null
"""

MYSQL_STAGING_TESTS = """version: 2

models:
  - name: stg_mysql_claims
    description: "Cleaned claims data with derived metrics"
    columns:
      - name: claim_id
        description: "Unique claim identifier"
        data_tests:
          - not_null
          - unique
      - name: claim_number
        description: "Business claim number"
        data_tests:
          - not_null
          - unique
      - name: total_charge_amount
        data_tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: current_status_code
        data_tests:
          - not_null
          - accepted_values:
              values: ['SUBMITTED','PENDING','IN_PROCESS','APPROVED','PAID','PARTIAL','DENIED','REJECTED','APPEALED','REVERSED','VOID','FORWARDED']

  - name: stg_mysql_claim_lines
    columns:
      - name: claim_line_id
        data_tests:
          - not_null
          - unique
      - name: claim_id
        data_tests:
          - not_null
          - relationships:
              to: ref('stg_mysql_claims')
              field: claim_id

  - name: stg_mysql_payments
    columns:
      - name: payment_id
        data_tests:
          - not_null
          - unique
      - name: claim_id
        data_tests:
          - not_null
          - relationships:
              to: ref('stg_mysql_claims')
              field: claim_id
      - name: payment_amount
        data_tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"

  - name: stg_mysql_adjustments
    columns:
      - name: adjustment_id
        data_tests:
          - not_null
          - unique
      - name: claim_id
        data_tests:
          - not_null

  - name: stg_mysql_insurance_plans
    columns:
      - name: plan_id
        data_tests:
          - not_null
          - unique
      - name: plan_code
        data_tests:
          - not_null
          - unique
      - name: deductible_tier
        data_tests:
          - accepted_values:
              values: ['No Deductible','Low Deductible','Medium Deductible','High Deductible']
"""

# ============= INTERMEDIATE TESTS =============

INT_TESTS = """version: 2

models:
  - name: int_patient_demographics
    description: "Enriched patient data with state/region/age categorization"
    columns:
      - name: patient_id
        data_tests:
          - not_null
          - unique
      - name: age_group
        data_tests:
          - accepted_values:
              values: ['Pediatric','Young Adult','Adult','Senior']

  - name: int_provider_with_facility
    description: "Provider data joined with specialty and facility"
    columns:
      - name: provider_id
        data_tests:
          - not_null
          - unique

  - name: int_encounter_full
    description: "Encounter data with rolled-up diagnoses and procedures"
    columns:
      - name: encounter_id
        data_tests:
          - not_null
          - unique

  - name: int_claim_with_provider
    description: "Claims joined with provider and plan details"
    columns:
      - name: claim_id
        data_tests:
          - not_null
          - unique

  - name: int_claim_financials
    description: "Claims with aggregated payment and adjustment metrics"
    columns:
      - name: claim_id
        data_tests:
          - not_null
          - unique
      - name: payment_status_category
        data_tests:
          - accepted_values:
              values: ['Fully Denied','Unpaid','Fully Paid','Partially Paid','Unknown']

  - name: int_encounter_with_claim
    description: "BRIDGE — joins clinical encounters with their financial claims"
    columns:
      - name: encounter_id
        data_tests:
          - not_null
          - unique
      - name: collection_status
        data_tests:
          - accepted_values:
              values: ['No Claim Filed','Unpaid','Fully Collected','Partially Collected']

  - name: int_payment_reconciliation
    columns:
      - name: payment_id
        data_tests:
          - not_null
          - unique

  - name: int_chronic_patients
    columns:
      - name: patient_id
        data_tests:
          - not_null
          - unique
      - name: chronic_category
        data_tests:
          - accepted_values:
              values: ['Healthy','Single Chronic','Multi-Chronic','High Complexity']
"""

# ============= MART TESTS =============

MART_CLINICAL_TESTS = """version: 2

models:
  - name: dim_patient
    description: "Patient dimension — final analytics-ready patient master"
    columns:
      - name: patient_key
        description: "Primary key for patient dimension"
        data_tests:
          - not_null
          - unique
      - name: medical_record_number
        data_tests:
          - not_null
          - unique
      - name: chronic_category
        data_tests:
          - not_null
      - name: age_group
        data_tests:
          - not_null
          - accepted_values:
              values: ['Pediatric','Young Adult','Adult','Senior']

  - name: dim_provider
    description: "Provider dimension"
    columns:
      - name: provider_key
        data_tests:
          - not_null
          - unique
      - name: npi_number
        data_tests:
          - not_null
          - unique
      - name: experience_level
        data_tests:
          - accepted_values:
              values: ['Junior','Mid-Level','Senior']

  - name: dim_facility
    columns:
      - name: facility_key
        data_tests:
          - not_null
          - unique
      - name: facility_size
        data_tests:
          - accepted_values:
              values: ['Outpatient Only','Small','Medium','Large']

  - name: dim_diagnosis
    columns:
      - name: diagnosis_key
        data_tests:
          - not_null
          - unique
      - name: risk_category
        data_tests:
          - accepted_values:
              values: ['High Risk','Behavioral','Low Acuity','Standard']

  - name: dim_procedure
    columns:
      - name: procedure_key
        data_tests:
          - not_null
          - unique
      - name: cost_tier
        data_tests:
          - accepted_values:
              values: ['High Cost','Medium Cost','Low Cost']

  - name: dim_date
    description: "Date dimension — 10 years of calendar"
    columns:
      - name: date_key
        data_tests:
          - not_null
          - unique

  - name: fct_encounter
    description: "Encounter fact table"
    columns:
      - name: encounter_key
        data_tests:
          - not_null
          - unique
      - name: patient_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_patient')
              field: patient_key
      - name: provider_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_provider')
              field: provider_key
      - name: facility_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_facility')
              field: facility_key
"""

MART_FINANCIAL_TESTS = """version: 2

models:
  - name: dim_payer
    description: "Payer/insurance dimension"
    columns:
      - name: payer_key
        data_tests:
          - not_null
          - unique
      - name: plan_code
        data_tests:
          - not_null
          - unique
      - name: payer_segment
        data_tests:
          - accepted_values:
              values: ['Government','Commercial','Patient']

  - name: fct_claim
    description: "Claim fact table — central financial fact"
    columns:
      - name: claim_key
        data_tests:
          - not_null
          - unique
      - name: claim_number
        data_tests:
          - not_null
          - unique
      - name: patient_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_patient')
              field: patient_key
      - name: provider_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_provider')
              field: provider_key
      - name: payer_key
        data_tests:
          - not_null
          - relationships:
              to: ref('dim_payer')
              field: payer_key
      - name: total_charge_amount
        data_tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: aging_bucket
        data_tests:
          - accepted_values:
              values: ['No Balance','0-30 days','31-60 days','61-90 days','91-120 days','120+ days']
      - name: payment_status_category
        data_tests:
          - accepted_values:
              values: ['Fully Denied','Unpaid','Fully Paid','Partially Paid','Unknown']

  - name: fct_payment
    description: "Payment fact table"
    columns:
      - name: payment_key
        data_tests:
          - not_null
          - unique
      - name: claim_key
        data_tests:
          - not_null
          - relationships:
              to: ref('fct_claim')
              field: claim_key
      - name: payment_amount
        data_tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: reconciliation_status
        data_tests:
          - accepted_values:
              values: ['Zero Payment','Fully Paid','Overpayment','Underpaid Significantly','Partial Payment']
"""

# Write the YAML files
file_targets = [
    (PROJECT_ROOT / "models" / "staging" / "postgres" / "_pg_staging_tests.yml", PG_STAGING_TESTS),
    (PROJECT_ROOT / "models" / "staging" / "mysql" / "_mysql_staging_tests.yml", MYSQL_STAGING_TESTS),
    (PROJECT_ROOT / "models" / "intermediate" / "_int_tests.yml", INT_TESTS),
    (PROJECT_ROOT / "models" / "marts" / "clinical" / "_clinical_marts_tests.yml", MART_CLINICAL_TESTS),
    (PROJECT_ROOT / "models" / "marts" / "financial" / "_financial_marts_tests.yml", MART_FINANCIAL_TESTS),
]

for path, content in file_targets:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"  Created: {path.relative_to(PROJECT_ROOT)}")

print(f"\n5 schema test files created across all model layers")