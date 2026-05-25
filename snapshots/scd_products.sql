{% snapshot scd_products %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='product_id',
      strategy='check',
      check_cols=['product_name', 'category', 'unit_price', 'cost_price', 'in_stock']
    )
}}

select * from {{ source('raw', 'raw_products') }}

{% endsnapshot %}
