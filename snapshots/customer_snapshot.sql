{% snapshot CUSTOMER_SNAPSHOT %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols='all'
    )
}}

select * from {{ source('raw', 'RAW_CUSTOMERS') }}

{% endsnapshot %}