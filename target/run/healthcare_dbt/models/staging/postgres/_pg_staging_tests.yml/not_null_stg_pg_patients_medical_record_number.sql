
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select medical_record_number
from HEALTHCARE_DW.STAGING.stg_pg_patients
where medical_record_number is null



  
  
      
    ) dbt_internal_test