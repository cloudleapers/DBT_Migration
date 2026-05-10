{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_allergies') }}
),

renamed as (
    select
        allergy_id,
        patient_id,
        allergen,
        reaction,
        severity,
        identified_date,
        is_active,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
