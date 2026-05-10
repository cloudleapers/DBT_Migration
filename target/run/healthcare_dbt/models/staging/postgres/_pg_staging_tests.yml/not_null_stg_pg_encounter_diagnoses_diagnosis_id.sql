
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select diagnosis_id
from HEALTHCARE_DW.STAGING.stg_pg_encounter_diagnoses
where diagnosis_id is null



  
  
      
    ) dbt_internal_test