{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounter_procedures') }}
),

renamed as (
    select
        procedure_id,
        encounter_id,
        cpt_code,
        performed_by                                    as performed_by_provider_id,
        performed_date,
        units,
        charge_amount,
        notes                                           as procedure_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
