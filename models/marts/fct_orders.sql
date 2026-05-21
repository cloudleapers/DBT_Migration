
--fct_orders
select
    order_id,
    customer_id,
    product_id,
    order_date,
    order_status,
    quantity,
    unit_price,
    discount_pct,
    gross_revenue,
    gross_profit
from {{ ref('int_orders_join') }}