
    
    

select
    claim_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.fct_claim
where claim_key is not null
group by claim_key
having count(*) > 1


