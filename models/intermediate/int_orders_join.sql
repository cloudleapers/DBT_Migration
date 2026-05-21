select
    o.order_id,
    o.order_date,
    o.order_status,
    o.quantity,
    o.unit_price,
    o.discount_pct,
    o.gross_revenue,
    o.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    o.product_id,
    p.product_name,
    p.category,
    p.cost_price,
    round(o.gross_revenue - (p.cost_price * o.quantity), 2) as gross_profit
from {{ ref('stg_orders') }} o
inner join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
inner join {{ ref('stg_products') }}  p on o.product_id  = p.product_id