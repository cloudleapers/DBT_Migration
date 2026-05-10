
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    plan_code as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_payer
where plan_code is not null
group by plan_code
having count(*) > 1



  
  
      
    ) dbt_internal_test