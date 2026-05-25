{{
    config(
        schema='MARTS'
    )
}}

with final_fct_ords as(
    select
        c.customer_id,
        c.customer_name,
        c.country,
        c.is_active as customer_status,
        o.order_id,
        o.order_date,
        p.product_id,
        p.product_name,
        p.category,
        o.quantity,
        o.unit_price,
        o.discount_pct,
        o.gross_amount,
        o.discount_amount,
        o.net_amount,
        (((o.quantity * o.unit_price) - (o.quantity * o.unit_price * o.discount_pct / 100))-(o.quantity * p.cost_price)) as profit,
        p.margin_category
    from {{ source('stage','stg_orders') }} o
    left join {{ ref('dim_customers') }} c
        on o.customer_id = c.customer_id
    left join {{ ref('dim_products') }} p
        on o.product_id = p.product_id
)
select * from final_fct_ords