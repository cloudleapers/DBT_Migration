
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        chronic_category as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.INTERMEDIATE.int_chronic_patients
    group by chronic_category

)

select *
from all_values
where value_field not in (
    'Healthy','Single Chronic','Multi-Chronic','High Complexity'
)



  
  
      
    ) dbt_internal_test