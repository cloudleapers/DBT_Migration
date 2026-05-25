select
    c.customer_id,
    c.customer_name,
    c.country,
    c.is_active as customer_status,
    o.order_date,
    p.product_id,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price,
    o.discount_pct,
    (o.quantity * o.unit_price) as gross_sales,
    (gross_sales * o.discount_pct / 100) as discount_amount,
    (gross_sales - discount_amount) as net_sales,
    (net_sales - (o.quantity * p.cost_price)) as profit
from {{ source('stage', 'stg_orders') }} o
left join {{ ref('dim_customers') }} c
    on o.customer_id = c.customer_id
left join {{ ref('dim_products') }} p
    on o.product_id = p.product_id