
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_adjustments
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_adjustments
),

renamed as (
    select
        adjustment_id,
        claim_id,
        claim_line_id,
        adjustment_code,
        adjustment_amount,
        adjustment_date,
        notes                                           as adjustment_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_adjustments' as _dbt_source_model

    from source
)

select * from renamed
  );

