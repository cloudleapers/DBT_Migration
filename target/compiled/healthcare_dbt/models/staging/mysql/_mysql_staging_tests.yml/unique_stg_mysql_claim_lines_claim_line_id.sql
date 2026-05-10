
    
    

select
    claim_line_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_claim_lines
where claim_line_id is not null
group by claim_line_id
having count(*) > 1


