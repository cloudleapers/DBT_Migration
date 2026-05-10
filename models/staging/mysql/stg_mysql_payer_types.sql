{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_payer_types') }}
),

renamed as (
    select
        payer_type_id,
        type_code                                       as payer_type_code,
        type_name                                       as payer_type_name,
        description                                     as payer_type_description,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
