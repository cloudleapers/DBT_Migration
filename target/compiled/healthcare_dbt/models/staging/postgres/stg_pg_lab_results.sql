

with source as (
    select * from HEALTHCARE_DW.RAW.pg_lab_results
),

renamed as (
    select
        result_id,
        lab_order_id,
        result_value,
        result_unit,
        reference_range,
        is_abnormal,
        result_date,
        notes                                           as result_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_lab_results' as _dbt_source_model

    from source
)

select * from renamed