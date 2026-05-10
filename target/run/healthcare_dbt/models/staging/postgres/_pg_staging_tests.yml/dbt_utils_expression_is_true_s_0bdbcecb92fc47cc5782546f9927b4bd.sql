
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from HEALTHCARE_DW.STAGING.stg_pg_patients

where not(age >= 0 and age <= 120)


  
  
      
    ) dbt_internal_test