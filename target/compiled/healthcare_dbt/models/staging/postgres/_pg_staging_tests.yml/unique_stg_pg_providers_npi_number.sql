
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_pg_providers
where npi_number is not null
group by npi_number
having count(*) > 1


