
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_charge_amount
from HEALTHCARE_DW.STAGING.stg_mysql_claims
where total_charge_amount is null



  
  
      
    ) dbt_internal_test