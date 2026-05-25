select
    product_id,
    trim(product_name) as product_name,
    {{ title_case('category') }} as category,
    unit_price,
    cost_price,
    in_stock,
    round((unit_price - cost_price) / nullif(unit_price, 0) * 100,2) as margin_pct,
    created_at
from {{ source('raw', 'PRODUCTS') }}
where
    {{ not_null('product_id') }}
    and {{ not_null('product_name') }}
    and {{ not_null('category') }}
    and {{ filter('category') }} <> 'TEST'
    and {{ positive_value('unit_price') }}
    and in_stock >= 0