
    
    

select
    medical_record_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_pg_patients
where medical_record_number is not null
group by medical_record_number
having count(*) > 1


