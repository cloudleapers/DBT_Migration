

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_billing_codes
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
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_billing_codes' as _dbt_source_model

    from source
)

select * from renamed