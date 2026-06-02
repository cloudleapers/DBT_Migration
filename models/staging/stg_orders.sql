-- models/staging/stg_orders.sql
select
    o.order_id,
    o.customer_id,
    o.product_id,
    o.quantity,
    o.unit_price,
    o.discount_pct,
    o.order_date,
    upper(trim(o.order_status)) as order_status,
    round(o.quantity * o.unit_price, 2) as gross_amount,
    round(o.quantity * o.unit_price * o.discount_pct / 100, 2) as discount_amount,
    round(o.quantity * o.unit_price * (1 - o.discount_pct/100), 2) as net_amount
from {{ source('raw', 'RAW_ORDERS') }} o
where o.quantity > 0
  and o.unit_price > 0
  and o.discount_pct between 0 and 100
  and o.order_date is not null
  and o.customer_id in (select customer_id from {{ ref('stg_customers') }})
  and o.product_id in (select product_id from {{ ref('stg_products') }})
