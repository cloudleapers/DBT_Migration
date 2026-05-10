
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_adjustment_codes
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_adjustment_codes
),

renamed as (
    select
        adjustment_code_id,
        code                                            as adjustment_code,
        description                                     as adjustment_description,
        category                                        as adjustment_category,
        is_denial,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_adjustment_codes' as _dbt_source_model

    from source
)

select * from renamed
  );

