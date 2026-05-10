
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        cost_tier as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_procedure
    group by cost_tier

)

select *
from all_values
where value_field not in (
    'High Cost','Medium Cost','Low Cost'
)



  
  
      
    ) dbt_internal_test