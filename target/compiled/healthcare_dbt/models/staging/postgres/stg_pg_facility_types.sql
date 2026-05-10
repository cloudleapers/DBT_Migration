

with source as (
    select * from HEALTHCARE_DW.RAW.pg_facility_types
),

renamed as (
    select
        type_id                                         as facility_type_id,
        type_name                                       as facility_type_name,
        description                                     as facility_type_description,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_facility_types' as _dbt_source_model

    from source
)

select * from renamed