
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payer_key
from HEALTHCARE_DW.MART.dim_payer
where payer_key is null



  
  
      
    ) dbt_internal_test