
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        aging_bucket as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.fct_claim
    group by aging_bucket

)

select *
from all_values
where value_field not in (
    'No Balance','0-30 days','31-60 days','61-90 days','91-120 days','120+ days'
)



  
  
      
    ) dbt_internal_test