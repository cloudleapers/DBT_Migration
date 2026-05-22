{{ config(materialized = 'view') }}

select 
	product_id,
	trim(product_name) as product_name,
	{{ clean_text('category') }} as category,
    cast(unit_price as number(10,2)) as unit_price,
    cast(cost_price as number(10,2)) as cost_price,
	in_stock,
	{{ margin_pct('unit_price', 'cost_price') }} as gross_margin,

    created_at
from {{source('raw', 'raw_products')}}
where category is not null
	and unit_price>0
	and cost_price>0
	and in_stock>=0
	and initcap(lower(trim(category)))!= 'Test'