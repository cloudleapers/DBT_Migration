

with source as (
    select * from HEALTHCARE_DW.RAW.pg_lab_orders
),

renamed as (
    select
        lab_order_id,
        encounter_id,
        patient_id,
        provider_id,
        test_name,
        test_code,
        ordered_date,
        status                                          as order_status,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_lab_orders' as _dbt_source_model

    from source
)

select * from renamed