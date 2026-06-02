{% snapshot scd_orders %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='order_id',
        strategy='check',
        check_cols=[
            'customer_id',
            'product_id',
            'order_date',
            'order_status',
            'quantity',
            'unit_price',
            'discount_pct'
        ]
    )
}}

SELECT *
FROM {{ source('raw', 'RAW_ORDERS') }}

{% endsnapshot %}