
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    medical_record_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_patient
where medical_record_number is not null
group by medical_record_number
having count(*) > 1



  
  
      
    ) dbt_internal_test