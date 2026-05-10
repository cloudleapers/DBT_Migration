

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claim_status_history
),

renamed as (
    select
        history_id,
        claim_id,
        status_code,
        status_date,
        status_time,
        changed_by,
        notes                                           as status_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_claim_status_history' as _dbt_source_model

    from source
)

select * from renamed