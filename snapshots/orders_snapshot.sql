{% snapshot scd_orders %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='order_id',
      strategy='check',
      check_cols=['quantity', 'unit_price', 'discount_pct', 'order_status']
    )
}}

select * from {{ source('raw', 'RAW_ORDERS') }}

{% endsnapshot %}