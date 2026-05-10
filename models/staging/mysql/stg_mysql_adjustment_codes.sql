{{ config(materialized='view') }}

with source as (
    select * from {{ source('mysql_claims', 'mysql_adjustment_codes') }}
),

renamed as (
    select
        adjustment_code_id,
        code                                            as adjustment_code,
        description                                     as adjustment_description,
        category                                        as adjustment_category,
        is_denial,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
