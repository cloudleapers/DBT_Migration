{{ config(materialized='table') }}

with cpt as (
    select * from {{ ref('stg_pg_cpt_codes') }}
),

billing as (
    select * from {{ ref('stg_mysql_billing_codes') }}
),

final as (
    select
        coalesce(c.cpt_code, b.billing_code)            as procedure_key,
        coalesce(c.procedure_description, b.code_description) as procedure_description,
        coalesce(c.procedure_category, 'Other')         as procedure_category,
        coalesce(c.base_cost, b.base_charge, 0)         as base_cost,
        coalesce(b.code_type, 'CPT')                    as code_type,
        case
            when coalesce(c.base_cost, b.base_charge, 0) > 5000 then 'High Cost'
            when coalesce(c.base_cost, b.base_charge, 0) > 500 then 'Medium Cost'
            else 'Low Cost'
        end                                             as cost_tier,
        current_timestamp()                             as dim_created_at
    from cpt c
    full outer join billing b on c.cpt_code = b.billing_code
)

select * from final
