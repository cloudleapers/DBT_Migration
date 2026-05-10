{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_patients') }}
),

renamed as (
    select
        patient_id,
        mrn                                              as medical_record_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                   as full_name,
        date_of_birth,
        datediff('year', date_of_birth, current_date()) as age,
        gender,
        race,
        ethnicity,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        email,
        primary_provider_id,
        is_active,
        registered_date,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed