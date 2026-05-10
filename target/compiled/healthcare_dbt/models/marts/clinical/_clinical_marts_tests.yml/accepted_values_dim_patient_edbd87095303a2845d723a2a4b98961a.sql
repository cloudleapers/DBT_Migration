
    
    

with all_values as (

    select
        age_group as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_patient
    group by age_group

)

select *
from all_values
where value_field not in (
    'Pediatric','Young Adult','Adult','Senior'
)


