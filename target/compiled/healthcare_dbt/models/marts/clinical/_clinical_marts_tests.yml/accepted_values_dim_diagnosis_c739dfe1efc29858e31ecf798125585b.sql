
    
    

with all_values as (

    select
        risk_category as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_diagnosis
    group by risk_category

)

select *
from all_values
where value_field not in (
    'High Risk','Behavioral','Low Acuity','Standard'
)


