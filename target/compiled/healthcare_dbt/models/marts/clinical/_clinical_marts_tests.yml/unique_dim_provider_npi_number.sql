
    
    

select
    npi_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_provider
where npi_number is not null
group by npi_number
having count(*) > 1


