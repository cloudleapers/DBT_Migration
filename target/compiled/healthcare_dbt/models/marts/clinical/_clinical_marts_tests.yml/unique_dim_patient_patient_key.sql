
    
    

select
    patient_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_patient
where patient_key is not null
group by patient_key
having count(*) > 1


