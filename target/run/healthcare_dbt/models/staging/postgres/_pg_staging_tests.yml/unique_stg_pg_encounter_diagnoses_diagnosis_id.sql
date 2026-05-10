
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    diagnosis_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_pg_encounter_diagnoses
where diagnosis_id is not null
group by diagnosis_id
having count(*) > 1



  
  
      
    ) dbt_internal_test