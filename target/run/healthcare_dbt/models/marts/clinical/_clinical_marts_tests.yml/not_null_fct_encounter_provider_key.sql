
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select provider_key
from HEALTHCARE_DW.MART.fct_encounter
where provider_key is null



  
  
      
    ) dbt_internal_test