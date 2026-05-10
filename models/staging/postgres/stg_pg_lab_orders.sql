{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_lab_orders') }}
),

renamed as (
    select
        lab_order_id,
        encounter_id,
        patient_id,
        provider_id,
        test_name,
        test_code,
        ordered_date,
        status                                          as order_status,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
