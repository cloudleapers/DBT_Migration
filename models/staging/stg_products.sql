{{
    config(
        schema='STAGING'
    )
}}

with cleaned_products as (

    select
        product_id,
        {{ plain_trim('product_name') }} as product_name,
        initcap({{ plain_trim('category') }}) as category,
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

    where {{ not_null('product_id') }}
      and {{ not_null('product_name') }}
      and unit_price > 0
      and in_stock >= 0
      and {{ upper_trim('category') }} != 'TEST'

)

select *
from cleaned_products