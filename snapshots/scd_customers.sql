{% snapshot scd_customers %}

{{
    config(
      target_database='DBT_PRACTICE',
      target_schema='snapshots',
      unique_key='customer_id',
      
      strategy='timestamp',
      updated_at='_loaded_at',
    )
}}

select * from {{ source('raw', 'raw_customers') }}

{% endsnapshot %}
