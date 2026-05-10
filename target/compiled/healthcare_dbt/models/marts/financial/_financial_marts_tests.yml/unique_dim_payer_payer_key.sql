
    
    

select
    payer_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.dim_payer
where payer_key is not null
group by payer_key
having count(*) > 1


