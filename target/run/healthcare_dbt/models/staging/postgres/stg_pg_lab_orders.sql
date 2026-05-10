
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_lab_orders
  
  
  
  
  as (
    

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
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_lab_orders' as _dbt_source_model

    from source
)

select * from renamed
  );

