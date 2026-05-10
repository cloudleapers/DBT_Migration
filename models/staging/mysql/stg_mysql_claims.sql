{{ config(materialized='view') }}

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
