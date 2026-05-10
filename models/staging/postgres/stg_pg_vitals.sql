{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_vitals') }}
),

renamed as (
    select
        vital_id,
        encounter_id,
        patient_id,
        measured_date,
        systolic_bp,
        diastolic_bp,
        heart_rate,
        respiratory_rate,
        temperature_f,
        weight_kg,
        height_cm,
        oxygen_saturation,
        case
            when systolic_bp >= 140 or diastolic_bp >= 90 then 'Hypertensive'
            when systolic_bp >= 120 or diastolic_bp >= 80 then 'Elevated'
            else 'Normal'
        end                                             as bp_classification,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
