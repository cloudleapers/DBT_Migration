
    
    

with child as (
    select patient_key as from_field
    from HEALTHCARE_DW.MART.fct_encounter
    where patient_key is not null
),

parent as (
    select patient_key as to_field
    from HEALTHCARE_DW.MART.dim_patient
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


