
    
    

with all_values as (

    select
        payment_status_category as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.fct_claim
    group by payment_status_category

)

select *
from all_values
where value_field not in (
    'Fully Denied','Unpaid','Fully Paid','Partially Paid','Unknown'
)


