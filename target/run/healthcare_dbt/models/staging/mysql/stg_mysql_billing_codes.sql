
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_billing_codes
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_billing_codes
),

renamed as (
    select
        billing_code_id,
        code                                            as billing_code,
        description                                     as code_description,
        code_type,
        base_charge,
        is_active,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_billing_codes' as _dbt_source_model

    from source
)

select * from renamed
  );

