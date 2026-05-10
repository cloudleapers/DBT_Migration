
    
    

select
    claim_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.INTERMEDIATE.int_claim_financials
where claim_id is not null
group by claim_id
having count(*) > 1


