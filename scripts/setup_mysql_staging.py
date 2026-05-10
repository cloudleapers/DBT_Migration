"""
Creates all 12 MySQL staging models cleanly using Python.
Avoids PowerShell brace-eating issues.
"""
from pathlib import Path

PROJECT_ROOT = Path(r"C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt")
STAGING_PATH = PROJECT_ROOT / "models" / "staging" / "mysql"
STAGING_PATH.mkdir(parents=True, exist_ok=True)

MODELS = {
    "stg_mysql_payer_types.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_payer_types') }}
),

renamed as (
    select
        payer_type_id,
        type_code                                       as payer_type_code,
        type_name                                       as payer_type_name,
        description                                     as payer_type_description,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_insurance_plans.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_insurance_plans') }}
),

renamed as (
    select
        plan_id,
        plan_code,
        plan_name,
        carrier_id,
        payer_type_id,
        plan_type,
        deductible_amount,
        copay_amount,
        out_of_pocket_max,
        is_active,
        effective_date,
        case
            when deductible_amount = 0 then 'No Deductible'
            when deductible_amount <= 1000 then 'Low Deductible'
            when deductible_amount <= 3000 then 'Medium Deductible'
            else 'High Deductible'
        end                                             as deductible_tier,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_billing_codes.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_billing_codes') }}
),

renamed as (
    select
        billing_code_id,
        code                                            as billing_code,
        description                                     as code_description,
        code_type,
        base_charge,
        is_active,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_claim_status_codes.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_status_codes') }}
),

renamed as (
    select
        status_code_id,
        status_code,
        status_name,
        description                                     as status_description,
        is_terminal,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_adjustment_codes.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_adjustment_codes') }}
),

renamed as (
    select
        adjustment_code_id,
        code                                            as adjustment_code,
        description                                     as adjustment_description,
        category                                        as adjustment_category,
        is_denial,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_claims.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claims') }}
),

renamed as (
    select
        claim_id,
        claim_number,
        patient_id,
        patient_mrn                                     as medical_record_number,
        encounter_id,
        encounter_number,
        provider_id,
        provider_npi,
        facility_id,
        carrier_id,
        plan_id,
        service_date,
        submission_date,
        datediff('day', service_date, submission_date) as days_to_submit,
        total_charge_amount,
        total_allowed_amount,
        total_paid_amount,
        total_charge_amount - total_paid_amount         as outstanding_balance,
        patient_responsibility,
        current_status_code,
        primary_diagnosis,
        claim_type,
        is_clean_claim,
        filing_indicator,
        case
            when total_charge_amount = 0 then 0
            else round((total_paid_amount / total_charge_amount) * 100, 2)
        end                                             as payment_ratio_pct,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_claim_lines.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_lines') }}
),

renamed as (
    select
        claim_line_id,
        claim_id,
        line_number,
        cpt_code,
        modifier,
        units,
        unit_price,
        charge_amount,
        allowed_amount,
        paid_amount,
        diagnosis_pointer,
        service_date,
        status_code                                     as line_status_code,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_payments.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_payments') }}
),

renamed as (
    select
        payment_id,
        claim_id,
        payment_number,
        carrier_id,
        payment_amount,
        payment_date,
        payment_method,
        check_number,
        era_number,
        is_posted,
        posted_date,
        case
            when posted_date is null then null
            else datediff('day', payment_date, posted_date)
        end                                             as days_to_post,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_adjustments.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_adjustments') }}
),

renamed as (
    select
        adjustment_id,
        claim_id,
        claim_line_id,
        adjustment_code,
        adjustment_amount,
        adjustment_date,
        notes                                           as adjustment_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_remittance_advice.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_remittance_advice') }}
),

renamed as (
    select
        remittance_id,
        claim_id,
        payer_id,
        era_number,
        check_number,
        remittance_date,
        total_billed,
        total_allowed,
        total_paid,
        total_adjustment,
        notes                                           as remittance_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_claim_status_history.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_status_history') }}
),

renamed as (
    select
        history_id,
        claim_id,
        status_code,
        status_date,
        status_time,
        changed_by,
        notes                                           as status_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",

    "stg_mysql_claim_attachments.sql": """{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_attachments') }}
),

renamed as (
    select
        attachment_id,
        claim_id,
        attachment_type,
        file_name,
        file_size_kb,
        uploaded_date,
        uploaded_by,
        notes                                           as attachment_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
""",
}

SOURCES_YML = """version: 2

sources:
  - name: mysql_claims
    description: "Claims and financial data from Aiven MySQL HealthCare_THP"
    database: HEALTHCARE_DW
    schema: RAW

    tables:
      - name: mysql_payer_types
      - name: mysql_insurance_plans
      - name: mysql_billing_codes
      - name: mysql_claim_status_codes
      - name: mysql_adjustment_codes
      - name: mysql_claims
      - name: mysql_claim_lines
      - name: mysql_payments
      - name: mysql_adjustments
      - name: mysql_remittance_advice
      - name: mysql_claim_status_history
      - name: mysql_claim_attachments
"""

# Write all model files (UTF-8 without BOM, LF line endings)
for filename, content in MODELS.items():
    file_path = STAGING_PATH / filename
    file_path.write_text(content, encoding="utf-8", newline="\n")
    print(f"  Created: {filename}")

# Write sources.yml
sources_path = STAGING_PATH / "_mysql_sources.yml"
sources_path.write_text(SOURCES_YML, encoding="utf-8", newline="\n")
print(f"  Created: _mysql_sources.yml")

print(f"\n12 MySQL staging models + 1 sources.yml created in:")
print(f"  {STAGING_PATH}")