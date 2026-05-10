

with source as (
    select * from HEALTHCARE_DW.RAW.pg_icd10_codes
),

renamed as (
    select
        code                                            as icd10_code,
        description                                     as diagnosis_description,
        category                                        as disease_category,
        is_chronic,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_icd10_codes' as _dbt_source_model

    from source
)

select * from renamed