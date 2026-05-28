{% snapshot scd_orders %}

{{
    config(
        target_database='DBT_PRACTICE',
        target_schema='SNAPSHOTS',
        unique_key='order_id',
        strategy='check',
        check_cols=[
            'quantity',
            'unit_price',
            'discount_pct',
            'order_status'
        ],

        post_hook="{{ update_snapshot_active(this) }}"
    )
}}

select
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity,
    unit_price,
    discount_pct,
    order_status,

    current_timestamp() as created_at,

    'YES' as is_active

from {{ source('raw', 'RAW_ORDERS') }}

{% endsnapshot %}
