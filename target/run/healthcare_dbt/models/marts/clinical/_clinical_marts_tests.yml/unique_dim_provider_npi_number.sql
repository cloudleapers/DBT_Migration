
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_provider
where npi_number is not null
group by npi_number
having count(*) > 1



  
  
      
    ) dbt_internal_test