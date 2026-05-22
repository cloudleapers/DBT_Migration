select
product_id,
trim(product_name) as product_name,
initcap(trim(category)) as category,
unit_price,
cost_price,
in_stock,
round((unit_price - cost_price) / nullif(unit_price, 0) * 100, 2) as margin_pct,
created_at
from {{ source('raw','PRODUCTS') }}
where product_id is  not null
and product_name is not null
  and category is not null 
  and category != 'TEST'
  and unit_price > 0 
  and in_stock >= 0