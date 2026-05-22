select
    c.customer_id,
    c.customer_name,
    c.country,
    c.customer_region,
    c.is_active as customer_status,

    o.order_id,
    o.order_date,

    p.product_id,
    p.product_name,
    p.category,

    o.quantity,
    o.unit_price,
    o.discount_pct,

    (o.quantity * o.unit_price) as gross_sales,

    (o.quantity * o.unit_price * o.discount_pct / 100) as discount_amount,

    (o.quantity * o.unit_price)
      - (o.quantity * o.unit_price * o.discount_pct / 100) as net_sales,

    (o.quantity * p.cost_price) as total_cost,

    (
        ((o.quantity * o.unit_price)
        - (o.quantity * o.unit_price * o.discount_pct / 100))
        - (o.quantity * p.cost_price)
    ) as profit,

    case
        when p.margin_pct >= 60 then 'High'
        when p.margin_pct >= 50 then 'Medium'
        else 'Low'
    end as margin_category

from {{ source('stage','stg_orders') }} o
left join {{ ref('dim_customers') }} c
    on o.customer_id = c.customer_id
left join {{ ref('dim_products') }} p
    on o.product_id = p.product_id