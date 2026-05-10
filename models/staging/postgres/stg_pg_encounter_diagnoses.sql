{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounter_diagnoses') }}
),

renamed as (
    select
        diagnosis_id,
        encounter_id,
        icd10_code,
        diagnosis_type,
        diagnosed_date,
        notes                                           as diagnosis_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
