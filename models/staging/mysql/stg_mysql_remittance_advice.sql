{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_remittance_advice') }}
),

renamed as (
    select
        remittance_id,
        claim_id,
        payer_id,
        era_number,
        check_number,
        remittance_date,
        total_billed,
        total_allowed,
        total_paid,
        total_adjustment,
        notes                                           as remittance_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
