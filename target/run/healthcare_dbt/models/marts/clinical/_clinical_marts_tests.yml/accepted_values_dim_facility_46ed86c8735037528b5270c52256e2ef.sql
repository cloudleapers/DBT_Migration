
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        facility_size as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_facility
    group by facility_size

)

select *
from all_values
where value_field not in (
    'Outpatient Only','Small','Medium','Large'
)



  
  
      
    ) dbt_internal_test