{% snapshot scd_customers %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols=['first_name', 'last_name', 'email', 'phone', 'country', 'is_active']
    )
}}

select * from {{ source('raw', 'raw_customers') }}

{% endsnapshot %}


