{% snapshot scd_products %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='product_id',
        strategy='check',
        check_cols=[
            'product_name',
            'category',
            'unit_price',
            'cost_price',
            'in_stock'
        ]
    )
}}

SELECT *
FROM {{ source('raw', 'RAW_PRODUCTS') }}

{% endsnapshot %}