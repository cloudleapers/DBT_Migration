
--stg_orders
select
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    discount_pct,
    upper(trim(order_status))  as order_status,
    round(quantity * unit_price * (1 - discount_pct / 100), 2) as gross_revenue
from {{ source('raw', 'RAW_ORDERS') }}
where quantity > 0
  and unit_price > 0
  and discount_pct <= 100