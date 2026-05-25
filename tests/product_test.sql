-- tests/product_checks.sql
SELECT 
    product_id,
    unit_price,
    cost_price,
    in_stock
FROM {{ source('stg', 'stg_products') }}
WHERE unit_price < 0 
   OR cost_price < 0 
   OR in_stock < 0
