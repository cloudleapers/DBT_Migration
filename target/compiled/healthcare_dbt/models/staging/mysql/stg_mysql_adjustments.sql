

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_adjustments
),

renamed as (
    select
        adjustment_id,
        claim_id,
        claim_line_id,
        adjustment_code,
        adjustment_amount,
        adjustment_date,
        notes                                           as adjustment_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_mysql_adjustments' as _dbt_source_model

    from source
)

select * from renamed