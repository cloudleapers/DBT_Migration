--stg_products
select
    product_id,
    trim(product_name) as product_name,
    initcap(trim(category)) as category,
    unit_price,
    cost_price,
    in_stock,
    round((unit_price - cost_price) / nullif(unit_price, 0) * 100, 2) as margin_pct
from {{ source('raw', 'RAW_PRODUCTS') }}
where unit_price > 0
  and in_stock >= 0
  and upper(trim(category)) != 'TEST'
  and product_id is not null
  and product_name is not null