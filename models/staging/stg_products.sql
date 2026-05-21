{{ config(materialized = 'view') }}

select 
	product_id,
	trim(product_name) as product_name,
	initcap(lower(trim(category))) as category,
	unit_price,
	cost_price,
	in_stock,
	created_at,
from {{source('raw', 'raw_products')}}
where category is not null
	and unit_price>0
	and cost_price>0
	and in_stock>=0
	and initcap(lower(trim(category)))!= 'Test'