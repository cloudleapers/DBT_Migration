{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_cpt_codes') }}
),

renamed as (
    select
        code                                            as cpt_code,
        description                                     as procedure_description,
        category                                        as procedure_category,
        base_cost,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
