
    
    

select
    plan_code as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
where plan_code is not null
group by plan_code
having count(*) > 1


