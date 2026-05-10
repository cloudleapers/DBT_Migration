
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_remittance_advice
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_remittance_advice
),

renamed as (
    select
        remittance_id,
        claim_id,
        payer_id,
        era_number,
        check_number,
        remittance_date,
        total_billed,
        total_allowed,
        total_paid,
        total_adjustment,
        notes                                           as remittance_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_remittance_advice' as _dbt_source_model

    from source
)

select * from renamed
  );

