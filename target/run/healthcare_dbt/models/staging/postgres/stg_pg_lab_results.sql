
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_lab_results
  
  
  
  
  as (
    

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
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_lab_results' as _dbt_source_model

    from source
)

select * from renamed
  );

