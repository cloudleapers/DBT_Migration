select
    customer_id,
    coalesce(first_name, 'N/A') as first_name,
    last_name,
    email,
    coalesce(phone, 'N/A') as phone,
    country,
    registration_date,
    is_active
from {{ ref('stg_customers') }}