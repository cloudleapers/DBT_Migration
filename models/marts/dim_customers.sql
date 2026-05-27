select

    customer_id,
    first_name,
    last_name,
    case
    when email = 'invalid' then 'N/A'
    else email
    end as email,
    case when phone is null or phone = '' then 'N/A' 
    else phone 
    end as phone,
    country,
    signup_date,
    is_active

from {{ ref('stg_customers') }}
where first_name != 'TEST' and last_name != 'USER'