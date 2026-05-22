{{ config(
    materialized='table'
) }}

select

        o.order_id,
        o.customer_id,
        o.product_id,

        o.order_date,
        o.quantity,
        o.unit_price,
        o.discount_pct,
        o.gross_amount,
        o.discount_amount,
        o.net_amount,
        o.order_status,

        c.country as customer_country,
        p.category as product_category,

        o.created_at

    from {{ source('stg', 'stg_orders') }} o

    left join {{ ref('dim_customers') }} c
        on o.customer_id = c.customer_id

    left join {{ ref('dim_products') }} p
        on o.product_id = p.product_id