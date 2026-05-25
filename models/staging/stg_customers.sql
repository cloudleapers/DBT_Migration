--stg_customers
select
    customer_id,
    initcap({{ clean_text('first_name') }}) as first_name,
    initcap({{ clean_text('last_name') }}) as last_name,
    lower({{ clean_text('email') }}) as email,
    {{ clean_text('phone') }} as phone,
    initcap({{ clean_text('country') }}) as country,
    try_to_date(signup_date, 'YYYY-MM-DD') as signup_date,
    case
        when upper(trim(is_active)) in ('Y','1','YES','TRUE') then true
        else false
    end as is_active
from {{ source('raw', 'RAW_CUSTOMERS') }}
where {{ clean_text('email') }} like '%@%.%'
  and {{ upper_trim('first_name') }} != 'TEST'
  and customer_id is not null
qualify row_number() over (partition by lower({{ clean_text('email') }}) order by customer_id asc) = 1
order by customer_id