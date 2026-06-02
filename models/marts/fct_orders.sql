
SELECT
    o.order_id,
    o.order_date,
    o.order_status,

    -- customer details
    o.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,

    -- product details
    o.product_id,
    p.name              AS product_name,     
    p.category          AS product_category,

    -- order financials
    o.quantity,
    o.unit_price,
    o.discount_pct,
    o.gross_amount,
    o.discount_amount,
    o.net_amount

FROM {{ ref('stg_orders') }}   o
LEFT JOIN {{ ref('stg_customers') }} c ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('stg_products') }}  p ON o.product_id  = p.product_id