
  
    

create or replace transient table HEALTHCARE_DW.MART.fct_claim
    
    
    
    as (

with claims as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_claim_with_provider
),

financials as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_claim_financials
),

final as (
    select
        c.claim_id                                      as claim_key,
        c.claim_number,
        c.patient_id                                    as patient_key,
        c.provider_id                                   as provider_key,
        c.facility_id                                   as facility_key,
        c.plan_id                                       as payer_key,
        c.encounter_id                                  as encounter_key,
        c.service_date                                  as service_date_key,
        c.submission_date                               as submission_date_key,
        c.primary_diagnosis                             as primary_diagnosis_key,
        c.days_to_submit,
        c.total_charge_amount,
        c.total_allowed_amount,
        c.total_paid_amount,
        c.outstanding_balance,
        c.patient_responsibility,
        c.payment_ratio_pct,
        f.payment_count,
        f.total_payment_received,
        f.adjustment_count,
        f.total_adjustments,
        c.current_status_code,
        c.status_name                                   as current_status_name,
        c.is_terminal                                   as is_terminal_status,
        c.claim_type,
        c.is_clean_claim,
        c.filing_indicator,
        f.payment_status_category,
        f.has_eft_payment,
        f.has_check_payment,
        f.has_medical_necessity_denial,
        f.has_coding_issue,
        case
            when c.outstanding_balance <= 0 then 'No Balance'
            when datediff('day', c.submission_date, current_date()) <= 30 then '0-30 days'
            when datediff('day', c.submission_date, current_date()) <= 60 then '31-60 days'
            when datediff('day', c.submission_date, current_date()) <= 90 then '61-90 days'
            when datediff('day', c.submission_date, current_date()) <= 120 then '91-120 days'
            else '120+ days'
        end                                             as aging_bucket,
        current_timestamp()                             as fct_created_at
    from claims c
    left join financials f on c.claim_id = f.claim_id
)

select * from final
    )
;


  