{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_icd10_codes') }}
),

renamed as (
    select
        code                                            as icd10_code,
        description                                     as diagnosis_description,
        category                                        as disease_category,
        is_chronic,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
