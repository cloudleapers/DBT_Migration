SELECT *
FROM {{ ref('stg_customers') }}
WHERE email NOT LIKE '%@%'