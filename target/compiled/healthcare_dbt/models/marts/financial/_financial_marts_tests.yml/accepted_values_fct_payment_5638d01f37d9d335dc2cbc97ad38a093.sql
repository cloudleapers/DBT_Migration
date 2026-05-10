
    
    

with all_values as (

    select
        reconciliation_status as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.fct_payment
    group by reconciliation_status

)

select *
from all_values
where value_field not in (
    'Zero Payment','Fully Paid','Overpayment','Underpaid Significantly','Partial Payment'
)


