
    
    

select
    claim_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.INTERMEDIATE.int_claim_with_provider
where claim_id is not null
group by claim_id
having count(*) > 1


