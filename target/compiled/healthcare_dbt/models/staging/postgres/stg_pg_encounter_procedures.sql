

with source as (
    select * from HEALTHCARE_DW.RAW.pg_encounter_procedures
),

renamed as (
    select
        procedure_id,
        encounter_id,
        cpt_code,
        performed_by                                    as performed_by_provider_id,
        performed_date,
        units,
        charge_amount,
        notes                                           as procedure_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_encounter_procedures' as _dbt_source_model

    from source
)

select * from renamed