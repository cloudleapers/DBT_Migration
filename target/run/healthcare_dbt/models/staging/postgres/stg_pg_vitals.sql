
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_vitals
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_vitals
),

renamed as (
    select
        vital_id,
        encounter_id,
        patient_id,
        measured_date,
        systolic_bp,
        diastolic_bp,
        heart_rate,
        respiratory_rate,
        temperature_f,
        weight_kg,
        height_cm,
        oxygen_saturation,
        case
            when systolic_bp >= 140 or diastolic_bp >= 90 then 'Hypertensive'
            when systolic_bp >= 120 or diastolic_bp >= 80 then 'Elevated'
            else 'Normal'
        end                                             as bp_classification,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_vitals' as _dbt_source_model

    from source
)

select * from renamed
  );

