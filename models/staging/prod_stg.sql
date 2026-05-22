with source as (
select * from {{ source('raw', 'RAW_PRODUCTS') }}
),

prod_mod  as (
select
product_id,
trim(product_name) as product_name,
trim(upper(category)) as category,
nullif(try_cast(unit_price as number(10,2)), 0) as unit_price,
nullif(try_cast(cost_price as number(10,2)), 0) as cost_price,
nullif(try_cast(in_stock as integer), 0) as in_stock,
created_at,
_loaded_at
from source
)
select * from prod_mod
where product_name != 'TEST PRODUCT' and category != 'TEST'