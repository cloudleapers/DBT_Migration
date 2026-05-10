

with source as (
    select * from HEALTHCARE_DW.RAW.pg_employees
),

renamed as (
    select
        employee_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        job_title,
        department,
        facility_id,
        hire_date,
        is_active,
        email,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_employees' as _dbt_source_model

    from source
)

select * from renamed