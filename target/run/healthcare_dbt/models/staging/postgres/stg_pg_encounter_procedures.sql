
  create or replace   view HEALTHCARE_DW.STAGING.stg_pg_encounter_procedures
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.pg_encounter_procedures
),

renamed as (
    select
        procedure_id,
        encounter_id,
        cpt_code,
        performed_by                                    as performed_by_provider_id,
        performed_date,
        units,
        charge_amount,
        notes                                           as procedure_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_pg_encounter_procedures' as _dbt_source_model

    from source
)

select * from renamed
  );

