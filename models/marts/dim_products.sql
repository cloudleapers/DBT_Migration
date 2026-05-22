select
product_id,
product_name,
category,
unit_price,
cost_price,
in_stock,
margin_pct,
case
    when margin_pct >= 60 then 'High'
    when margin_pct >= 50 then 'Medium'
    else 'Low'
end as margin_category,
created_at
from {{ source('stage', 'stg_products') }}