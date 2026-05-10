

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_remittance_advice
),

renamed as (
    select
        remittance_id,
        claim_id,
        payer_id,
        era_number,
        check_number,
        remittance_date,
        total_billed,
        total_allowed,
        total_paid,
        total_adjustment,
        notes                                           as remittance_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_remittance_advice' as _dbt_source_model

    from source
)

select * from renamed