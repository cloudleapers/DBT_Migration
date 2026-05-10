

with source as (
    select * from HEALTHCARE_DW.RAW.pg_cpt_codes
),

renamed as (
    select
        code                                            as cpt_code,
        description                                     as procedure_description,
        category                                        as procedure_category,
        base_cost,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_cpt_codes' as _dbt_source_model

    from source
)

select * from renamed