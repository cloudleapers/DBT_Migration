{{config(
    materialized='table'
)}}
select
    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    gross_margin,
    in_stock,
    created_at
from {{ source('stg', 'stg_products') }}