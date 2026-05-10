
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select age
from HEALTHCARE_DW.STAGING.stg_pg_patients
where age is null



  
  
      
    ) dbt_internal_test