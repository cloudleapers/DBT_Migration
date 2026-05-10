
    
    

select
    claim_number as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_claims
where claim_number is not null
group by claim_number
having count(*) > 1


