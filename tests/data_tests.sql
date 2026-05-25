-- This test checks if any order has an invalid discount percentage.
-- If it returns any rows, the test fails.
SELECT 
    order_id, 
    discount_pct
FROM {{ source('stg', 'stg_orders') }} -- or your staging model
WHERE discount_pct > 100 OR discount_pct < 0
