
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select medical_record_number
from HEALTHCARE_DW.MART.dim_patient
where medical_record_number is null



  
  
      
    ) dbt_internal_test