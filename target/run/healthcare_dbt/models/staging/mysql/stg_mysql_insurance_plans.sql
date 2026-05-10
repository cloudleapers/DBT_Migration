
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_insurance_plans
),

renamed as (
    select
        plan_id,
        plan_code,
        plan_name,
        carrier_id,
        payer_type_id,
        plan_type,
        deductible_amount,
        copay_amount,
        out_of_pocket_max,
        is_active,
        effective_date,
        case
            when deductible_amount = 0 then 'No Deductible'
            when deductible_amount <= 1000 then 'Low Deductible'
            when deductible_amount <= 3000 then 'Medium Deductible'
            else 'High Deductible'
        end                                             as deductible_tier,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_insurance_plans' as _dbt_source_model

    from source
)

select * from renamed
  );

