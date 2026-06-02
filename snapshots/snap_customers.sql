-- snap_customers.sql
{% snapshot snap_customers %}
{{ config(
    target_schema='SNAPSHOTS',
    unique_key='customer_id',
    strategy='check',
    check_cols=['email', 'country', 'is_active']
) }}

select * from {{ ref('stg_customers') }}
{% endsnapshot %}
