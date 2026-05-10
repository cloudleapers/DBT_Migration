
    
    

select
    patient_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.INTERMEDIATE.int_patient_demographics
where patient_id is not null
group by patient_id
having count(*) > 1


