{{ config(
    materialized='table'
) }}

with orders as (
select * from {{ source('stage', 'orders_stg') }}
),

customers as (
select * from {{ source('stage', 'cust_stg') }}
),

products as (
select * from {{ source('stage', 'prod_stg') }}
)

select
    o.order_id,
    o.order_date,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    p.product_id,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price,
    o.discount_pct,
    (o.quantity * o.unit_price) as gross_sales,
    ((o.quantity * o.unit_price)-((o.quantity * o.unit_price) * (o.discount_pct / 100))) 
    as net_sales,
    (p.cost_price * o.quantity) as total_cost,
    (((o.quantity * o.unit_price)-((o.quantity * o.unit_price) * (o.discount_pct / 100))) -
    (p.cost_price * o.quantity)) as gross_profit,
    o.order_status
from orders o

left join customers c
    on o.customer_id = c.customer_id

left join products p
    on o.product_id = p.product_id