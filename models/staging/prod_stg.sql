with source as (
select * from {{ source('raw', 'RAW_PRODUCTS') }}
),

prod_mod  as (
select
product_id,
trim(product_name) as product_name,
trim(upper(category)) as category,
try_cast(unit_price as number(10,2)) as unit_price,
try_cast(cost_price as number(10,2)) as cost_price,
try_cast(in_stock as integer) as in_stock,
created_at,
_loaded_at
from source
)
select * from prod_mod