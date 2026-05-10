
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_employees
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_employees
),

renamed as (
    select
        employee_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        job_title,
        department,
        facility_id,
        hire_date,
        is_active,
        email,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_employees' as _dbt_source_model

    from source
)

select * from renamed
  );

