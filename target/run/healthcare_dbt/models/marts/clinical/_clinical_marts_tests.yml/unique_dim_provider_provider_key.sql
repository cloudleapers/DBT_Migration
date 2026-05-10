
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    provider_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_provider
where provider_key is not null
group by provider_key
having count(*) > 1



  
  
      
    ) dbt_internal_test