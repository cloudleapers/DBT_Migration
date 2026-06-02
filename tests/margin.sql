SELECT *
FROM {{ ref('stg_products') }}
WHERE margin_pct < -100
   OR margin_pct > 100