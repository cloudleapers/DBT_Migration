
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    adjustment_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_adjustments
where adjustment_id is not null
group by adjustment_id
having count(*) > 1



  
  
      
    ) dbt_internal_test