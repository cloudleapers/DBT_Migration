{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_specialty_types') }}
),

renamed as (
    select
        specialty_id,
        specialty_name,
        description                                     as specialty_description,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
