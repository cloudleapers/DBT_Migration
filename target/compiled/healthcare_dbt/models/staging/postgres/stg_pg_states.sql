

with source as (
    select * from HEALTHCARE_DW.RAW.pg_states
),

renamed as (
    select
        state_code,
        state_name,
        region,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_states' as _dbt_source_model

    from source
)

select * from renamed