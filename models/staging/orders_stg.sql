with source as (
select * from {{ source('raw', 'RAW_ORDERS') }}

),
orders_mod  as (
select
order_id,
customer_id,
product_id,
order_date,
try_cast(quantity as integer) as quantity,
try_cast(unit_price as number(10,2)) as unit_price,
try_cast(discount_pct as number(5,2)) as discount_pct,
upper(trim(order_status)) as order_status,
created_at,
_loaded_at
from source
)
select * from orders_mod