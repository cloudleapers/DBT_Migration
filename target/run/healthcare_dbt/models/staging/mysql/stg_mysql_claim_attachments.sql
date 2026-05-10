
  create or replace   view HEALTHCARE_DW.STAGING.stg_mysql_claim_attachments
  
  
  
  
  as (
    

with source as (
    select * from HEALTHCARE_DW.RAW.mysql_claim_attachments
),

renamed as (
    select
        attachment_id,
        claim_id,
        attachment_type,
        file_name,
        file_size_kb,
        uploaded_date,
        uploaded_by,
        notes                                           as attachment_notes,
        created_at,
        
    current_timestamp() as _dbt_loaded_at,
    '95cc7fbd-111f-4135-8ff7-e37b7ee4ef4e' as _dbt_run_id,
    'stg_mysql_claim_attachments' as _dbt_source_model

    from source
)

select * from renamed
  );

