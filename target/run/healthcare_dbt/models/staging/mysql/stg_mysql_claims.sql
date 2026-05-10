
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_claims
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claims
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
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_claims' as _dbt_source_model

    from source
)

select * from renamed
  );

