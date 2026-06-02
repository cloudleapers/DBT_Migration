SELECT *
FROM {{ ref('fct_orders') }}
WHERE customer_id IS NULL
   OR product_id IS NULL