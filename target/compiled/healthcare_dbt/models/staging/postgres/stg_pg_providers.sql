

with source as (
    select * from HEALTHCARE_DW.RAW.pg_providers
),

renamed as (
    select
        provider_id,
        npi_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        specialty_id,
        facility_id,
        license_number,
        hire_date,
        datediff('year', hire_date, current_date())    as tenure_years,
        is_active,
        email,
        phone,
        created_at,
        updated_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_providers' as _dbt_source_model

    from source
)

select * from renamed