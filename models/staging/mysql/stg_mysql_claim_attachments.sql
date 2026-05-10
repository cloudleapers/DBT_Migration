{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_attachments') }}
),

renamed as (
    select
        attachment_id,
        claim_id,
        attachment_type,
        file_name,
        file_size_kb,
        uploaded_date,
        uploaded_by,
        notes                                           as attachment_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
