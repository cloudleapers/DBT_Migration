{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_adjustments') }}
),

renamed as (
    select
        adjustment_id,
        claim_id,
        claim_line_id,
        adjustment_code,
        adjustment_amount,
        adjustment_date,
        notes                                           as adjustment_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
