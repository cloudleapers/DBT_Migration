
    
    

with all_values as (

    select
        gender as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.STAGING.stg_pg_patients
    group by gender

)

select *
from all_values
where value_field not in (
    'M','F','O'
)


