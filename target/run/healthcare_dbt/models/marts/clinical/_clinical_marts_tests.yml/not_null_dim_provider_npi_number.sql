
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select npi_number
from HEALTHCARE_DW.MART.dim_provider
where npi_number is null



  
  
      
    ) dbt_internal_test