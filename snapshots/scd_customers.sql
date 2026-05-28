{% snapshot scd_customers %}

{{
    config(
        target_database='DBT_PRACTICE',
        target_schema='SNAPSHOTS',
        unique_key='customer_id',
        strategy='check',
        check_cols=[
            'first_name',
            'last_name',
            'email',
            'phone',
            'country'
        ],

        post_hook="{{ update_snapshot_active(this) }}"
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    country,

    current_timestamp() as created_at,

    'YES' as is_active

from {{ source('raw', 'RAW_CUSTOMERS') }}

{% endsnapshot %}