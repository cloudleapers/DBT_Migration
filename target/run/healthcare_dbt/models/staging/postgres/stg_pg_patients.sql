
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_patients
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_patients
),

renamed as (
    select
        patient_id,
        mrn                                              as medical_record_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                   as full_name,
        date_of_birth,
        datediff('year', date_of_birth, current_date()) as age,
        gender,
        race,
        ethnicity,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        email,
        primary_provider_id,
        is_active,
        registered_date,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_patients' as _dbt_source_model

    from source
)

select * from renamed
  );

