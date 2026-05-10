{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_facilities') }}
),

renamed as (
    select
        facility_id,
        facility_name,
        type_id                                         as facility_type_id,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        capacity_beds,
        is_active,
        opened_date,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
