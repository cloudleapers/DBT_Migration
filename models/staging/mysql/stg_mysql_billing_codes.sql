{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_billing_codes') }}
),

renamed as (
    select
        billing_code_id,
        code                                            as billing_code,
        description                                     as code_description,
        code_type,
        base_charge,
        is_active,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
