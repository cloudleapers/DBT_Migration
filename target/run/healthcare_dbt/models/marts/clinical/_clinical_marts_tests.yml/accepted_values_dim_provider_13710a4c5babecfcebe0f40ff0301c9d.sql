
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        experience_level as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_provider
    group by experience_level

)

select *
from all_values
where value_field not in (
    'Junior','Mid-Level','Senior'
)



  
  
      
    ) dbt_internal_test