-- Final clean product list for reporting
select
    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    unit_price - cost_price            as gross_margin,   -- profit per unit
    in_stock
from {{ ref('stg_products') }}