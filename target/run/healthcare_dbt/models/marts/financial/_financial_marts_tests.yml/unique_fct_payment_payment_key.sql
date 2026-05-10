
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    payment_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.fct_payment
where payment_key is not null
group by payment_key
having count(*) > 1



  
  
      
    ) dbt_internal_test