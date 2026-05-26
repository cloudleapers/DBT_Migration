with source as (

    select *
    from {{ source('raw', 'RAW_ORDERS') }}

),
orders_mod as (
select

        order_id,

        trim(customer_id) as customer_id,

        product_id,

        order_date,

        {{ to_integer('quantity') }} as quantity,

        {{ to_decimal('unit_price', 10, 2) }} as unit_price,

        {{ to_decimal('discount_pct', 5, 2) }} as discount_pct,

        {{ to_upper_trim('order_status') }} as order_status,

        created_at,

        _loaded_at

    from source

)

select *
from orders_mod