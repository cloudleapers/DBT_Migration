{{
    config(
        schema='STAGING'
    )
}}

with cleaned_products as (

    select
        product_id,
        trim(product_name) as product_name,
        initcap(trim(category)) as category,
        try_cast(unit_price as number(10,2)) as unit_price,
        cost_price,
        in_stock,

        round(
            (unit_price - cost_price)
            / nullif(unit_price, 0) * 100,
            2
        ) as margin_pct,
        created_at

    from {{ source('raw', 'RAW_PRODUCTS') }}

    where product_id is not null
      and product_name is not null
      and unit_price > 0
      and in_stock >= 0
      and upper(trim(category)) != 'TEST'

)

select *
from cleaned_products