with New_DT as (

    select
        customer_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        trim(phone) as phone,
        initcap(trim(country)) as country,
        try_to_date(signup_date, 'YYYY-MM-DD') as signup_date,

        case
            when upper(trim(is_active)) in ('Y', '1') then true
            else false
        end as is_active,

        row_number() over (
            partition by lower(trim(email))
            order by customer_id desc
        ) as repeat_num

    from {{ source('raw', 'RAW_CUSTOMERS') }}

    where customer_id is not null
      and email is not null
      and trim(email) like '%@%.%'
      and upper(trim(country)) != 'TEST'

)

select *
from New_DT
where repeat_num = 1