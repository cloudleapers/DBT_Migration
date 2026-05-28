{{
    config(
        schema='STAGING'
    )
}}

with cleaned_data as (

    select
        customer_id,
        {{ plain_trim('first_name') }} as first_name,
        {{ plain_trim('last_name') }} as last_name,
        {{ clean_email('email') }} as email,
        {{ plain_trim('phone') }} as phone,
        initcap({{ plain_trim('country') }}) as country,
        try_to_date(signup_date, 'YYYY-MM-DD') as signup_date,

        case
            when {{ status_fun('is_active') }} = 'True'
                then true
            else false
        end as is_active,

        created_at

    from {{ source('raw', 'RAW_CUSTOMERS') }}

    where {{ not_null('customer_id') }}
      and {{ not_null('email') }}
      and {{ clean_email('email') }} like '%@%.%'
      and {{ upper_trim('country') }} != 'TEST'

),

deduped as (

    select *,
        row_number() over (
            partition by email
            order by customer_id asc
        ) as rn

    from cleaned_data

)

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    country,
    signup_date,
    is_active

from deduped
where rn = 1