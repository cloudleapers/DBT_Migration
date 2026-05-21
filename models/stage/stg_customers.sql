
 {# {{config(schema = 'STAGING')}} #}

select
customer_id,
trim(first_name) AS first_name,
trim(last_name) AS last_name,
case      
    when lower(trim(email))                -- remove spaces + convert lowercase 
        then replace(lower(trim(email)), '@@', '@')
    else lower(trim(email))
    end as email,
trim(phone) AS phone,
upper(trim(country)) AS country,
case
    when signup_date like '%/%'                      -- change 2024/02/10 → 2024-02-10
    then replace(signup_date, '/', '-')
    when signup_date like '__-__-____'               -- change 15-07-2024 → 2024-07-15
    then replace(signup_date, 'DD-MM-YYYY','YYYY-MM-DD' )
    else signup_date                                 -- keep already correct format
end as signup_date,
case
    when upper(trim(is_active)) IN ('Y', '1')
    then 'TRUE'
    else 'FALSE'
end as is_active,
created_at
from {{source('raw', 'RAW_CUSTOMERS')}}