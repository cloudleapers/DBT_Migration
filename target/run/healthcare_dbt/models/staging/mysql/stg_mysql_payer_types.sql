
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_payer_types
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_payer_types
),

renamed as (
    select
        payer_type_id,
        type_code                                       as payer_type_code,
        type_name                                       as payer_type_name,
        description                                     as payer_type_description,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_payer_types' as _dbt_source_model

    from source
)

select * from renamed
  );

