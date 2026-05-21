{{ config(
    materialized='view'
) }}

select
    customer_id,

    initcap(trim(first_name)) as first_name,
    initcap(trim(last_name)) as last_name,
    lower(trim(replace(email, '@@', '@'))) as email,
    phone,
    case
        when upper(trim(country)) in ('usa', 'us') then 'USA'
        when upper(trim(country)) = 'uk' then 'UK'
        else initcap(trim(country))
    end as country,
    coalesce(
        try_to_date(trim(signup_date)::varchar, 'YYYY-MM-DD'),
        try_to_date(trim(signup_date)::varchar, 'YYYY/MM/DD'),
        try_to_date(trim(signup_date)::varchar, 'DD-MM-YYYY')
) as registration_date,
    case
        when upper(trim(is_active)) in ('Y', '1') then 'Yes'
        else 'No'
    end as is_active,
    created_at

from {{ source('raw', 'raw_customers') }}

where customer_id is not null
  and email like '%@%.%'


qualify row_number() over (
    partition by lower(trim(email))
    order by created_at desc
) = 1