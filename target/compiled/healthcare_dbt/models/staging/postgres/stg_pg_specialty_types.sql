

with source as (
    select * from HEALTHCARE_DW.RAW.pg_specialty_types
),

renamed as (
    select
        specialty_id,
        specialty_name,
        description                                     as specialty_description,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_specialty_types' as _dbt_source_model

    from source
)

select * from renamed