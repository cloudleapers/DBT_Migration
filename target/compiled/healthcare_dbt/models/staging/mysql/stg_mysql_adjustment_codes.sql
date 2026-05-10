

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_adjustment_codes
),

renamed as (
    select
        adjustment_code_id,
        code                                            as adjustment_code,
        description                                     as adjustment_description,
        category                                        as adjustment_category,
        is_denial,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_adjustment_codes' as _dbt_source_model

    from source
)

select * from renamed