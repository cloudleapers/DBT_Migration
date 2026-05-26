{{ config(materialized='table', schema='MARTS') }}

SELECT
    product_id,
    name,             -- aliased from PRODUCT_NAME in stg_products
    category,
    unit_price,
    cost_price,
    stock,            -- aliased from IN_STOCK in stg_products
    margin_pct
FROM {{ ref('stg_products') }}