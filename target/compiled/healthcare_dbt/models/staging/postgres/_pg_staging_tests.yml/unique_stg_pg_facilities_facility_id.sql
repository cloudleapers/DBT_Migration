
    
    

select
    facility_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_pg_facilities
where facility_id is not null
group by facility_id
having count(*) > 1


