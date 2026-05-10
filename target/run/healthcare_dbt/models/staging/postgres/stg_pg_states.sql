
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_states
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_states
),

renamed as (
    select
        state_code,
        state_name,
        region,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_states' as _dbt_source_model

    from source
)

select * from renamed
  );

