
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select claim_id
from HEALTHCARE_DW.INTERMEDIATE.int_claim_with_provider
where claim_id is null



  
  
      
    ) dbt_internal_test