{% snapshot scd_products %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='product_id',
      strategy='check',
      check_cols= 'all'
    )
}}
select * from {{ source('raw', 'RAW_PRODUCTS') }}

{% endsnapshot %}