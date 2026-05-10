
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select chronic_category
from HEALTHCARE_DW.MART.dim_patient
where chronic_category is null



  
  
      
    ) dbt_internal_test