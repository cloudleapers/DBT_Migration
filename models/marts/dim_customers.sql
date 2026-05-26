{{ config(materialized='table', schema='MARTS') }}

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    is_active
FROM {{ ref('stg_customers') }}