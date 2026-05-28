select

    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    in_stock,
    margin_pct

from {{ source('stage','stg_products') }}