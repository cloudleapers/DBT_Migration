select
order_id,
customer_id,
product_id,
order_date,
quantity,
unit_price,
discount_pct,
upper(trim(order_status)) as order_status,
created_at
from {{ source('raw', 'ORDERS') }}
where quantity > 0
and unit_price > 0
and discount_pct between 0 and 100
and order_date is not null
and customer_id in (select customer_id from {{ source('raw', 'CUSTOMERS') }})
and product_id in (select product_id from {{ source('raw', 'PRODUCTS') }})
order by order_id asc 