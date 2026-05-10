
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select encounter_id
from HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
where encounter_id is null



  
  
      
    ) dbt_internal_test