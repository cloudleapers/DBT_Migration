
    
    

select
    encounter_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
where encounter_id is not null
group by encounter_id
having count(*) > 1


