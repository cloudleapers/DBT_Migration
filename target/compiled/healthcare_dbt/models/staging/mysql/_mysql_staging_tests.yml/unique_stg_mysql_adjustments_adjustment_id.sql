
    
    

select
    adjustment_id as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_adjustments
where adjustment_id is not null
group by adjustment_id
having count(*) > 1


