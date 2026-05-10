
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_encounter_diagnoses
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_encounter_diagnoses
),

renamed as (
    select
        diagnosis_id,
        encounter_id,
        icd10_code,
        diagnosis_type,
        diagnosed_date,
        notes                                           as diagnosis_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_encounter_diagnoses' as _dbt_source_model

    from source
)

select * from renamed
  );

