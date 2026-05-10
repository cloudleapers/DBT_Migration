{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_providers') }}
),

renamed as (
    select
        provider_id,
        npi_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        specialty_id,
        facility_id,
        license_number,
        hire_date,
        datediff('year', hire_date, current_date())    as tenure_years,
        is_active,
        email,
        phone,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
