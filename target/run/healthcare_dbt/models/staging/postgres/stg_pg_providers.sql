
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_providers
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_providers
),

renamed as (
    select
        provider_id,
        npi_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        specialty_id,
        facility_id,
        license_number,
        hire_date,
        datediff('year', hire_date, current_date())    as tenure_years,
        is_active,
        email,
        phone,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_providers' as _dbt_source_model

    from source
)

select * from renamed
  );

