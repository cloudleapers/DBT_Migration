--dim_customers
select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    is_active
from {{ ref('stg_customers') }}