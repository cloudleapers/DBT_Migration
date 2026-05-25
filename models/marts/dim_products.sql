select
product_id,
product_name,
category,
unit_price,
cost_price,
in_stock,
margin_pct,
created_at
from {{ source('stage', 'stg_products') }}