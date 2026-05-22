{{config(
    materialized='table'
)}}
select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    country,
    registration_date,
    is_active,
    created_at
from {{ source('stg', 'stg_customers') }}