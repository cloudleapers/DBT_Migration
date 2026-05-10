
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select plan_id
from HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
where plan_id is null



  
  
      
    ) dbt_internal_test