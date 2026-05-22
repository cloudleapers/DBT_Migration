{{ config(materialized='view') }}

select 
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    cast(unit_price as number(10,2)) as unit_price,
    discount_pct,
    {{ gross_amount('quantity', 'unit_price') }} as gross_amount,
    {{ discount_amount('quantity', 'unit_price', 'discount_pct') }} as discount_amount,
    {{ net_amount('quantity', 'unit_price', 'discount_pct') }} as net_amount,
    {{ clean_text('order_status') }} as order_status,
    created_at

from {{ source('raw', 'raw_orders') }}

where
    quantity > 0
    and unit_price > 0
    and discount_pct between 0 and 100
    and customer_id != 9999
    and product_id != 8888