select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    country,
    signup_date,
    is_active

from {{ source('stage','stg_customers') }}