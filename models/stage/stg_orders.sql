with sanitize_orders as (

    select
        order_id,
        customer_id,
        product_id,
        order_date,
        quantity,
        unit_price,
        discount_pct,
        upper(trim(order_status)) as order_status,

        round(
            quantity * unit_price,
            2
        ) as gross_amount,

        round(
            quantity * unit_price * discount_pct / 100,
            2
        ) as discount_amount,

        round(
            quantity * unit_price *
            (1 - discount_pct / 100),
            2
        ) as net_amount

    from {{ source('raw', 'RAW_ORDERS') }}

    where quantity > 0
      and unit_price > 0
      and discount_pct between 0 and 100
      and order_date is not null

)

select *
from sanitize_orders