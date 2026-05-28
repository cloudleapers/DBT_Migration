{% snapshot scd_products %}

{{
    config(
        target_database='DBT_PRACTICE',
        target_schema='SNAPSHOTS',
        unique_key='product_id',
        strategy='check',
        check_cols=[
            'product_name',
            'category',
            'unit_price',
            'cost_price',
            'in_stock'
        ],

        post_hook="{{ update_snapshot_active(this) }}"
    )
}}

select
    product_id,
    product_name,
    category,
    unit_price,
    cost_price,
    in_stock,

    current_timestamp() as created_at,

    'YES' as is_active

from {{ source('raw', 'RAW_PRODUCTS') }}

{% endsnapshot %}
