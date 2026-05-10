
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select facility_key
from HEALTHCARE_DW.MART.dim_facility
where facility_key is null



  
  
      
    ) dbt_internal_test