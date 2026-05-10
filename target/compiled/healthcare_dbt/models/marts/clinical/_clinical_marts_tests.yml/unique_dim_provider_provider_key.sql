
    
    

select
    provider_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_provider
where provider_key is not null
group by provider_key
having count(*) > 1


