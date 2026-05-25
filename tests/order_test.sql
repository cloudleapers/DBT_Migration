select * from {{ source('stg', 'stg_orders') }}
where
    quantity < 0
    and unit_price < 0
    and discount_pct > 100 and discount_pct < 0
    and customer_id = 9999
    and product_id = 8888