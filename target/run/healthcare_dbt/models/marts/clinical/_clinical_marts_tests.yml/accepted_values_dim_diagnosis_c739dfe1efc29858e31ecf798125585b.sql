
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

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



  
  
      
    ) dbt_internal_test