
    
    

with child as (
    select claim_key as from_field
    from HEALTHCARE_DW.MART.fct_payment
    where claim_key is not null
),

parent as (
    select claim_key as to_field
    from HEALTHCARE_DW.MART.fct_claim
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


