

with source as (
    select * from HEALTHCARE_DW.RAW.pg_prescriptions
),

renamed as (
    select
        prescription_id,
        encounter_id,
        patient_id,
        provider_id,
        medication_name,
        dosage,
        frequency,
        duration_days,
        refills,
        prescribed_date,
        is_controlled,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_prescriptions' as _dbt_source_model

    from source
)

select * from renamed