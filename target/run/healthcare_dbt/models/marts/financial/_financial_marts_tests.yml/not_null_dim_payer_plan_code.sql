
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select plan_code
from HEALTHCARE_DW.MART.dim_payer
where plan_code is null



  
  
      
    ) dbt_internal_test