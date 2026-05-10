{{ config(materialized='table') }}

with carriers as (
    select * from {{ ref('stg_pg_insurance_carriers') }}
),

plans as (
    select * from {{ ref('stg_mysql_insurance_plans') }}
),

payer_types as (
    select * from {{ ref('stg_mysql_payer_types') }}
),

final as (
    select
        p.plan_id                                       as payer_key,
        p.plan_code,
        p.plan_name,
        p.plan_type,
        p.deductible_tier,
        p.deductible_amount,
        p.copay_amount,
        p.out_of_pocket_max,
        p.carrier_id,
        c.carrier_name,
        c.carrier_type,
        pt.payer_type_id,
        pt.payer_type_name,
        p.is_active,
        p.effective_date,
        case
            when pt.payer_type_name = 'Medicare' then 'Government'
            when pt.payer_type_name = 'Medicaid' then 'Government'
            when pt.payer_type_name = 'Self-Pay' then 'Patient'
            else 'Commercial'
        end                                             as payer_segment,
        current_timestamp()                             as dim_created_at
    from plans p
    left join carriers c     on p.carrier_id = c.carrier_id
    left join payer_types pt on p.payer_type_id = pt.payer_type_id
)

select * from final
