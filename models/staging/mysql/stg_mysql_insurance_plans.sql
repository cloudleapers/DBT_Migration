{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_insurance_plans') }}
),

renamed as (
    select
        plan_id,
        plan_code,
        plan_name,
        carrier_id,
        payer_type_id,
        plan_type,
        deductible_amount,
        copay_amount,
        out_of_pocket_max,
        is_active,
        effective_date,
        case
            when deductible_amount = 0 then 'No Deductible'
            when deductible_amount <= 1000 then 'Low Deductible'
            when deductible_amount <= 3000 then 'Medium Deductible'
            else 'High Deductible'
        end                                             as deductible_tier,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
