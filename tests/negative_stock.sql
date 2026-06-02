SELECT *
FROM {{ ref('stg_products') }}
WHERE stock < 0