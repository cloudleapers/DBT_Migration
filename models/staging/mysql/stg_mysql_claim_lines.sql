{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_lines') }}
),

renamed as (
    select
        claim_line_id,
        claim_id,
        line_number,
        cpt_code,
        modifier,
        units,
        unit_price,
        charge_amount,
        allowed_amount,
        paid_amount,
        diagnosis_pointer,
        service_date,
        status_code                                     as line_status_code,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
