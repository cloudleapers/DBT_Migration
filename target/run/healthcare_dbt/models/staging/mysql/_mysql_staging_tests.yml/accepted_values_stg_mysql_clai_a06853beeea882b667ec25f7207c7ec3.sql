
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        current_status_code as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.STAGING.stg_mysql_claims
    group by current_status_code

)

select *
from all_values
where value_field not in (
    'SUBMITTED','PENDING','IN_PROCESS','APPROVED','PAID','PARTIAL','DENIED','REJECTED','APPEALED','REVERSED','VOID','FORWARDED'
)



  
  
      
    ) dbt_internal_test