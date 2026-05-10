
    
    

with all_values as (

    select
        payer_segment as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.dim_payer
    group by payer_segment

)

select *
from all_values
where value_field not in (
    'Government','Commercial','Patient'
)


