
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_specialty_types
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_specialty_types
),

renamed as (
    select
        specialty_id,
        specialty_name,
        description                                     as specialty_description,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_specialty_types' as _dbt_source_model

    from source
)

select * from renamed
  );

