
    
    

select
    procedure_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_pg_encounter_procedures
where procedure_id is not null
group by procedure_id
having count(*) > 1


