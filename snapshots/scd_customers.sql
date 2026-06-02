{% snapshot scd_customers %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='customer_id',
        strategy='check',
        check_cols=[
            'first_name',
            'last_name',
            'email',
            'country',
            'signup_date',
            'is_active'
        ]
    )
}}

SELECT *
FROM {{ source('raw', 'RAW_CUSTOMERS') }}

{% endsnapshot %}