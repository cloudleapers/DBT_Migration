with source  as (
select * from {{ source('raw', 'RAW_CUSTOMERS') }}
),
mod1 as (
select
customer_id,
trim(upper(first_name)) as first_name,
trim(upper(last_name)) as last_name,
CASE
    WHEN TRIM(LOWER(email)) LIKE '%@%.%'
         AND LENGTH(email) - LENGTH(REPLACE(email, '@', '')) = 1
    THEN email
    ELSE 'invalid'
end as email,
trim(phone) as phone,
trim(upper(country)) as country,
try_to_date(signup_date) as signup_date,
case
    when upper(is_active) in ('Y', '1', 'TRUE')
    then true
    else false
    end as is_active,
created_at,
_loaded_at
from source
)
select * from mod1