select
    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    unit_price - cost_price            as gross_margin,  
    in_stock
from {{ ref('stg_products') }}