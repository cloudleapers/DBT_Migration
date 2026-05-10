
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    claim_line_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_claim_lines
where claim_line_id is not null
group by claim_line_id
having count(*) > 1



  
  
      
    ) dbt_internal_test