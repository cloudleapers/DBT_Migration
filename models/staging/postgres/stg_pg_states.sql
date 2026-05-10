{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_states') }}
),

renamed as (
    select
        state_code,
        state_name,
        region,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
