
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_claim_status_history
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claim_status_history
),

renamed as (
    select
        history_id,
        claim_id,
        status_code,
        status_date,
        status_time,
        changed_by,
        notes                                           as status_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_claim_status_history' as _dbt_source_model

    from source
)

select * from renamed
  );

