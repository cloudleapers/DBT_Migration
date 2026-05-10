
    
    

with all_values as (

    select
        experience_level as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_provider
    group by experience_level

)

select *
from all_values
where value_field not in (
    'Junior','Mid-Level','Senior'
)


