select
customer_id,
concat(first_name,' ',last_name) as customer_name,
email,
phone,
country,
signup_date,
is_active,
case
    when country = 'India'
    then 'Domestic'
    else 'International'
    end as customer_region,
    created_at
from {{ source('stage', 'stg_customers') }}