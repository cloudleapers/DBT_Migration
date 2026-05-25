select
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    discount_pct,
    {{ filter('order_status') }} as order_status,
    created_at
from {{ source('raw', 'ORDERS') }}
where
    {{ positive_value('quantity') }}
    and {{ positive_value('unit_price') }}
    and {{ valid_range('discount_pct', 0, 100) }}
    and {{ not_null('order_date') }}
    and {{ valid_fk('customer_id', 'raw', 'CUSTOMERS', 'customer_id') }}
    and {{ valid_fk('product_id', 'raw', 'PRODUCTS', 'product_id') }}
order by order_id asc