{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounters') }}
),

renamed as (
    select
        encounter_id,
        encounter_number,
        patient_id,
        provider_id,
        facility_id,
        encounter_type,
        encounter_date,
        encounter_time,
        duration_minutes,
        chief_complaint,
        status                                          as encounter_status,
        case
            when encounter_type = 'Emergency'   then true
            when encounter_type = 'Urgent Care' then true
            else false
        end                                             as is_acute_visit,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
