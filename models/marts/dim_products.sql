
SELECT
    product_id,
    name,             
    category,
    unit_price,
    cost_price,
    stock,            
    margin_pct
FROM {{ ref('stg_products') }}