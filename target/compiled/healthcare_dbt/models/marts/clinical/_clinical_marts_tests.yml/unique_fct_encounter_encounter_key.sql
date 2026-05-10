
    
    

select
    encounter_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.fct_encounter
where encounter_key is not null
group by encounter_key
having count(*) > 1


