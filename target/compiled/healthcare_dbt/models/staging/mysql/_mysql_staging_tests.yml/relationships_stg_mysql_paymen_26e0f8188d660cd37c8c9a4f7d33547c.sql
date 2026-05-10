
    
    

with child as (
    select claim_id as from_field
    from HEALTHCARE_DW.STAGING.stg_mysql_payments
    where claim_id is not null
),

parent as (
    select claim_id as to_field
    from HEALTHCARE_DW.STAGING.stg_mysql_claims
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


