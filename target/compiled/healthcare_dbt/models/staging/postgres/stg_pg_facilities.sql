

with source as (
    select * from HEALTHCARE_DW.RAW.pg_facilities
),

renamed as (
    select
        facility_id,
        facility_name,
        type_id                                         as facility_type_id,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        capacity_beds,
        is_active,
        opened_date,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_facilities' as _dbt_source_model

    from source
)

select * from renamed