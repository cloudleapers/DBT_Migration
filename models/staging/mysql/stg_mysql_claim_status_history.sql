{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_status_history') }}
),

renamed as (
    select
        history_id,
        claim_id,
        status_code,
        status_date,
        status_time,
        changed_by,
        notes                                           as status_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
