WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_ORDERS') }}
),

filtered AS (
    SELECT * FROM source
    WHERE
        quantity > 0
        AND unit_price > 0
        AND discount_pct BETWEEN 0 AND 100
        AND order_date IS NOT NULL
        AND customer_id IN (SELECT customer_id FROM {{ ref('stg_customers') }})
        AND product_id  IN (SELECT product_id  FROM {{ ref('stg_products') }})
),

final AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        order_date,
        UPPER(TRIM(order_status))                                       AS order_status,
        quantity,
        CAST(unit_price AS NUMBER(10,2))                                AS unit_price,
        discount_pct,
        ROUND(quantity * unit_price, 2)                                 AS gross_amount,
        ROUND(quantity * unit_price * discount_pct / 100, 2)           AS discount_amount,
        ROUND(quantity * unit_price * (1 - discount_pct/100), 2)       AS net_amount
    FROM filtered
)

SELECT * FROM final