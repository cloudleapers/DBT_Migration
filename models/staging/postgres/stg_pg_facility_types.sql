{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_facility_types') }}
),

renamed as (
    select
        type_id                                         as facility_type_id,
        type_name                                       as facility_type_name,
        description                                     as facility_type_description,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
