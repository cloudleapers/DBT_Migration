

with source as (
    select * from HEALTHCARE_DW.RAW.pg_allergies
),

renamed as (
    select
        allergy_id,
        patient_id,
        allergen,
        reaction,
        severity,
        identified_date,
        is_active,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_allergies' as _dbt_source_model

    from source
)

select * from renamed