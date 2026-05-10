
    
    

select
    patient_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.INTERMEDIATE.int_chronic_patients
where patient_id is not null
group by patient_id
having count(*) > 1


