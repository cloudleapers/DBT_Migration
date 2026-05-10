{{ config(materialized='table') }}

with icd_codes as (
    select * from {{ ref('stg_pg_icd10_codes') }}
),

final as (
    select
        icd10_code                                      as diagnosis_key,
        diagnosis_description,
        disease_category,
        is_chronic,
        case
            when disease_category in ('Cardiovascular','Endocrine','Respiratory','Renal') then 'High Risk'
            when disease_category in ('Mental','Neurological') then 'Behavioral'
            when disease_category in ('Wellness','Symptoms') then 'Low Acuity'
            else 'Standard'
        end                                             as risk_category,
        current_timestamp()                             as dim_created_at
    from icd_codes
)

select * from final
