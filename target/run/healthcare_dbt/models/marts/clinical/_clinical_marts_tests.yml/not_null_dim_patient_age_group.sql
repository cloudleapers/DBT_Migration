
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select age_group
from HEALTHCARE_DW.MART.dim_patient
where age_group is null



  
  
      
    ) dbt_internal_test