
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_claim_lines
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claim_lines
),

renamed as (
    select
        claim_line_id,
        claim_id,
        line_number,
        cpt_code,
        modifier,
        units,
        unit_price,
        charge_amount,
        allowed_amount,
        paid_amount,
        diagnosis_pointer,
        service_date,
        status_code                                     as line_status_code,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_claim_lines' as _dbt_source_model

    from source
)

select * from renamed
  );

