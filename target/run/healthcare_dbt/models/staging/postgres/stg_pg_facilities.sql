
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_facilities
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_facilities
),

renamed as (
    select
        facility_id,
        facility_name,
        type_id                                         as facility_type_id,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        capacity_beds,
        is_active,
        opened_date,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_facilities' as _dbt_source_model

    from source
)

select * from renamed
  );

