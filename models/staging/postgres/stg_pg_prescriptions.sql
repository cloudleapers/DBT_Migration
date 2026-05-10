{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_prescriptions') }}
),

renamed as (
    select
        prescription_id,
        encounter_id,
        patient_id,
        provider_id,
        medication_name,
        dosage,
        frequency,
        duration_days,
        refills,
        prescribed_date,
        is_controlled,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
