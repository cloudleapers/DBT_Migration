

with source as (
    select * from HEALTHCARE_DW.RAW.pg_insurance_carriers
),

renamed as (
    select
        carrier_id,
        carrier_name,
        carrier_type,
        payer_id                                        as external_payer_id,
        phone,
        is_active,
        contract_start                                  as contract_start_date,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '9dc4592c-d32b-435d-9cd3-70c91313a374' as _dbt_run_id,
    'stg_pg_insurance_carriers' as _dbt_source_model

    from source
)

select * from renamed