{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_insurance_carriers') }}
),

renamed as (
    select
        carrier_id,
        carrier_name,
        carrier_type,
        payer_id                                        as external_payer_id,
        phone,
        is_active,
        contract_start                                  as contract_start_date,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
