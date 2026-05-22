select
customer_id,
coalesce(trim(first_name), 'N/A') as first_name,
trim(last_name) as last_name,
lower(replace(trim(email),'@@','@')) as email,
coalesce(trim(phone), 'N/A') AS phone,
initcap(trim(country)) as country,

coalesce(
        try_to_date(trim(signup_date), 'YYYY-MM-DD'),
        try_to_date(trim(signup_date), 'YYYY/MM/DD'),
        try_to_date(trim(signup_date), 'DD-MM-YYYY')
        ) as signup_date,
case
    when upper(trim(is_active)) IN ('Y', '1')
    then 'active'
    when upper(trim(is_active)) IN ('N', '0')
    then 'inactive'
    else 'N/A'
end as is_active,
created_at
from {{ source('raw', 'CUSTOMERS') }}
where customer_id is NOT NULL
and upper(trim(country)) <> 'TEST' 
and email is NOT NULL