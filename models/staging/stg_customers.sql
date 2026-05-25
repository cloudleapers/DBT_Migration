{{
    config(
        schema='STAGING'
    )
}}

with cleaned_data as (

    select
        customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        trim(phone) as phone,
        initcap(trim(country)) as country,
        try_to_date(signup_date, 'YYYY-MM-DD') as signup_date,

        case
            when upper(trim(is_active)) in ('Y','1') then true
            else false
        end as is_active,
        created_at

    from {{ source('raw', 'RAW_CUSTOMERS') }}

    where customer_id is not null
      and email is not null
      and trim(email) like '%@%.%'
      and upper(trim(country)) != 'TEST'

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