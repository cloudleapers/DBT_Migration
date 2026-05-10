
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_key
from HEALTHCARE_DW.MART.dim_patient
where patient_key is null



  
  
      
    ) dbt_internal_test