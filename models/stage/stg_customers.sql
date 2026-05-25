
select
    customer_id,
    {{ clean_text('first_name') }} as first_name,
    {{ clean_text('last_name') }} as last_name,
    {{ clean_email('email') }} as email,
    {{ clean_text('phone') }} as phone,
    {{ title_case('country') }} as country,
    {{ format_date('signup_date') }} as signup_date,
    {{ active_status('is_active') }} as is_active,
    {{ clean_text('created_at') }} as created_at
from {{ source('raw', 'CUSTOMERS') }}
where {{ not_null('customer_id') }}
    and {{ filter('country') }} <> 'TEST'
    and {{ not_null('email') }}
    and email like '%@%.%'
qualify row_number() over (partition by {{ clean_email('email') }}order by customer_id) = 1
order by customer_id asc