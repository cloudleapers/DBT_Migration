
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
        {{ clean_text('first_name') }}          AS first_name,
        {{ clean_text('last_name') }}           AS last_name,
        {{ validate_email('email') }}           AS email,
        {{ clean_text('country') }}             AS country,
        {{ safe_date('signup_date') }}          AS signup_date,
        {{ convert_boolean('is_active') }}      AS is_active
    FROM deduped
)

SELECT * FROM final