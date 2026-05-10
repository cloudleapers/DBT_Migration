
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select encounter_key
from HEALTHCARE_DW.MART.fct_encounter
where encounter_key is null



  
  
      
    ) dbt_internal_test