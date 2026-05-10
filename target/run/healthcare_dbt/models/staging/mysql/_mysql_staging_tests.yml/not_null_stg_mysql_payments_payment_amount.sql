
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_amount
from HEALTHCARE_DW.STAGING.stg_mysql_payments
where payment_amount is null



  
  
      
    ) dbt_internal_test