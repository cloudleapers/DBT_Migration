{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_lab_results') }}
),

renamed as (
    select
        result_id,
        lab_order_id,
        result_value,
        result_unit,
        reference_range,
        is_abnormal,
        result_date,
        notes                                           as result_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
