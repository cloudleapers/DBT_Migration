
    
    

select
    facility_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_facility
where facility_key is not null
group by facility_key
having count(*) > 1


