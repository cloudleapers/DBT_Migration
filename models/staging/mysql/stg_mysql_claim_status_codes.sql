{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_claim_status_codes') }}
),

renamed as (
    select
        status_code_id,
        status_code,
        status_name,
        description                                     as status_description,
        is_terminal,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
