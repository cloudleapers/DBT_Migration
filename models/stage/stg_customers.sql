
 {# {{config(schema = 'STAGING')}} #}

select
customer_id,
trim(first_name) AS first_name,
trim(last_name) AS last_name,
replace(lower(trim(email)), '@@', '@') as email,
trim(phone) AS phone,
upper(trim(country)) AS country,
replace(signup_date, '/', '-') as signup_date,
case
    when upper(trim(is_active)) IN ('Y', '1')
    then 'active'
    when upper(trim(is_active)) IN ('N', '0')
    then 'inactive'
    else 'invalid'
end as is_active,
created_at
from {{source('raw', 'RAW_CUSTOMERS')}}