{{ config(materialized='view', schema='STAGING') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_PRODUCTS') }}
),

filtered AS (
    SELECT * FROM source
    WHERE
        product_id IS NOT NULL
        AND product_name IS NOT NULL
        AND TRIM(product_name) != ''
        AND unit_price > 0
        AND in_stock >= 0
        AND UPPER(TRIM(category)) != 'TEST'
),

final AS (
    SELECT
        product_id,
        TRIM(product_name)                                                  AS name,
        INITCAP(TRIM(category))                                             AS category,
        CAST(unit_price AS NUMBER(10,2))                                    AS unit_price,
        CAST(cost_price AS NUMBER(10,2))                                    AS cost_price,
        in_stock                                                            AS stock,
        ROUND(
            (unit_price - cost_price) / NULLIF(unit_price, 0) * 100, 2
        )                                                                   AS margin_pct
    FROM filtered
)

SELECT * FROM final