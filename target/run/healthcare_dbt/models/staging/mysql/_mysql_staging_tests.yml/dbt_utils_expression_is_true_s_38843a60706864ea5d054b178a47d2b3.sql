
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from HEALTHCARE_DW.STAGING.stg_mysql_payments

where not(payment_amount >= 0)


  
  
      
    ) dbt_internal_test