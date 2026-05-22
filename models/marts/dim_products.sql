{{ config(
    materialized='table'
) }}

select

    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    in_stock,
round(
        ((unit_price - cost_price) / unit_price) * 100,2) as margin_pct

from {{ source('stage', 'prod_stg') }}