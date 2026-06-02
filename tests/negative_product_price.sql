SELECT *
FROM {{ ref('stg_products') }}
WHERE unit_price <= 0