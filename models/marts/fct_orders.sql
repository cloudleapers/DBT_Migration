with Cumilative as (

    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country,
        p.product_id,
        p.product_name,
        p.category,
        o.order_id,
        o.order_date,
        o.order_status
        o.quantity,
        o.unit_price,
        o.discount_pct,

        o.quantity * o.unit_price as total_sales,
        p.cost_price * o.quantity as total_cost,

        (o.net_amount - (p.cost_price * o.quantity), 2) as gross_profit,

        

    from {{ ref('stg_orders') }} o

    left join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id

    left join {{ ref('stg_products') }} p on o.product_id = p.product_id

)

select *
from Cumilative