
--dim_products
select
    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    margin_pct,
    in_stock
from {{ ref('stg_products') }}