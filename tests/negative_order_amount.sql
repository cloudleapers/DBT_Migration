SELECT *
FROM {{ ref('fct_orders') }}
WHERE net_amount <= 0