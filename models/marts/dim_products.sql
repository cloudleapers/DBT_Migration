{{
    config(
        materialized='incremental',
        schema = 'MARTS',

        pre_hook="""
        {% if is_incremental() %}
        update {{ this }} tgt
        set is_active = 'NO'
        from {{ source('stage', 'stg_products') }} src
        where tgt.product_id = src.product_id
          and tgt.product_name = src.product_name
          and tgt.is_active = 'YES'
          and (
                tgt.category <> src.category
             or tgt.unit_price <> src.unit_price
             or tgt.cost_price <> src.cost_price
             or tgt.in_stock <> src.in_stock
             or tgt.margin_pct <> src.margin_pct
          )
        {% endif %}
        """
    )
}}

with dim_prdts as (

    select
        product_id,
        product_name,
        category,
        unit_price,
        cost_price,
        in_stock,
        margin_pct,

        case
            when margin_pct >= 60 then 'High'
            when margin_pct >= 50 then 'Medium'
            else 'Low'
        end as margin_category,

        current_timestamp as created_at,
        'YES' as is_active

    from {{ source('stage', 'stg_products') }}

)
{% if is_incremental() %}
,

new_or_changed as (

    select src.*

    from dim_prdts src

    left join {{ this }} tgt
        on src.product_id = tgt.product_id
       and src.product_name = tgt.product_name
       and tgt.is_active = 'YES'

    where tgt.product_id is null

       or (
            tgt.category <> src.category
         or tgt.unit_price <> src.unit_price
         or tgt.cost_price <> src.cost_price
         or tgt.in_stock <> src.in_stock
         or tgt.margin_pct <> src.margin_pct
       )

)

select *
from new_or_changed

{% else %}

select *
from dim_prdts

{% endif %}