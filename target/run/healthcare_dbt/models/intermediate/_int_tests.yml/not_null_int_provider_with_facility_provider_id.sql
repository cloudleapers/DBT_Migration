
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select provider_id
from HEALTHCARE_DW.INTERMEDIATE.int_provider_with_facility
where provider_id is null



  
  
      
    ) dbt_internal_test