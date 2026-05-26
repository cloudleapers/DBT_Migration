with source as ( select * from {{ source('raw', 'RAW_PRODUCTS') }}

),
prod_mod as (

    select

        product_id,

        trim(product_name) as product_name,

        {{ clean_text('category') }} as category,

        {{ numeric_clean('unit_price', 10, 2) }} as unit_price,

        {{ numeric_clean('cost_price', 10, 2) }} as cost_price,

        {{ integer_clean('in_stock') }} as in_stock,

        created_at,

        _loaded_at

    from source

)

select *
from prod_mod
where upper(trim(product_name)) != 'TEST PRODUCT'
  and category != 'TEST'