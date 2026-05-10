
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select current_status_code
from HEALTHCARE_DW.STAGING.stg_mysql_claims
where current_status_code is null



  
  
      
    ) dbt_internal_test