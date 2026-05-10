
    
    

with all_values as (

    select
        deductible_tier as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
    group by deductible_tier

)

select *
from all_values
where value_field not in (
    'No Deductible','Low Deductible','Medium Deductible','High Deductible'
)


