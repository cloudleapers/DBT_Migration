{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_payments') }}
),

renamed as (
    select
        payment_id,
        claim_id,
        payment_number,
        carrier_id,
        payment_amount,
        payment_date,
        payment_method,
        check_number,
        era_number,
        is_posted,
        posted_date,
        case
            when posted_date is null then null
            else datediff('day', payment_date, posted_date)
        end                                             as days_to_post,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
