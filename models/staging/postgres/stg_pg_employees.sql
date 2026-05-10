{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_employees') }}
),

renamed as (
    select
        employee_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        job_title,
        department,
        facility_id,
        hire_date,
        is_active,
        email,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
