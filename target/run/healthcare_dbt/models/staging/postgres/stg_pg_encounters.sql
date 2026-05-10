
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_encounters
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_encounters
),

renamed as (
    select
        encounter_id,
        encounter_number,
        patient_id,
        provider_id,
        facility_id,
        encounter_type,
        encounter_date,
        encounter_time,
        duration_minutes,
        chief_complaint,
        status                                          as encounter_status,
        case
            when encounter_type = 'Emergency'   then true
            when encounter_type = 'Urgent Care' then true
            else false
        end                                             as is_acute_visit,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_encounters' as _dbt_source_model

    from source
)

select * from renamed
  );

