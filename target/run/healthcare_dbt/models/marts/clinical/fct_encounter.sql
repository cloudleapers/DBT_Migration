
  
    

create or replace transient table HEALTHCARE_DW.MART.fct_encounter
    
    
    
    as (

with encounters as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
),

final as (
    select
        encounter_id                                    as encounter_key,
        encounter_number,
        patient_id                                      as patient_key,
        provider_id                                     as provider_key,
        facility_id                                     as facility_key,
        encounter_date                                  as date_key,
        primary_icd10_code                              as primary_diagnosis_key,
        encounter_type,
        is_acute_visit,
        duration_minutes,
        total_diagnoses,
        total_procedures,
        total_procedure_charges,
        claims_per_encounter,
        total_billed,
        total_collected,
        total_outstanding,
        case
            when total_billed = 0 then 0
            else round((total_collected / total_billed) * 100, 2)
        end                                             as collection_rate_pct,
        latest_claim_status,
        had_clean_claim,
        collection_status,
        current_timestamp()                             as fct_created_at
    from encounters
)

select * from final
    )
;


  