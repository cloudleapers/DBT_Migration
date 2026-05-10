

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claim_status_codes
),

renamed as (
    select
        status_code_id,
        status_code,
        status_name,
        description                                     as status_description,
        is_terminal,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_claim_status_codes' as _dbt_source_model

    from source
)

select * from renamed