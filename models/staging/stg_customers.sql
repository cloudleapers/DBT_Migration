{{ config(materialized='view', schema='STAGING') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'RAW_CUSTOMERS') }}
),

filtered AS (
    SELECT * FROM source
    WHERE
        customer_id IS NOT NULL
        AND email IS NOT NULL
        AND email LIKE '%@%'          
        AND email NOT LIKE '%@@%'
        AND TRIM(email) != ''
        AND UPPER(TRIM(country)) != 'TEST'
),

deduped AS (
    SELECT * FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY LOWER(TRIM(email))
                ORDER BY customer_id ASC   
            ) AS rn
        FROM filtered
    )
    WHERE rn = 1
),

final AS (
    SELECT
        customer_id,
        INITCAP(TRIM(first_name))                           AS first_name,
        INITCAP(TRIM(last_name))                            AS last_name,
        LOWER(TRIM(email))                                  AS email,
        INITCAP(TRIM(country))                              AS country,
        TRY_TO_DATE(signup_date, 'YYYY-MM-DD')              AS signup_date,
        CASE
            WHEN UPPER(TRIM(is_active)) IN ('Y','1','YES','TRUE')  THEN TRUE
            WHEN UPPER(TRIM(is_active)) IN ('N','0','NO','FALSE')  THEN FALSE
            ELSE NULL
        END                                                 AS is_active
    FROM deduped
)

SELECT * FROM final