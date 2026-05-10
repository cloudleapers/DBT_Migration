
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_allergies
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_allergies
),

renamed as (
    select
        allergy_id,
        patient_id,
        allergen,
        reaction,
        severity,
        identified_date,
        is_active,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_allergies' as _dbt_source_model

    from source
)

select * from renamed
  );

