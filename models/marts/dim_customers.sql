select
customer_id,
concat(first_name,' ',last_name) as customer_name,
email,
phone,
country,
signup_date,
is_active,
created_at
from {{ source('stage', 'stg_customers') }}