

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_payments
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
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_payments' as _dbt_source_model

    from source
)

select * from renamed