
  create or replace   view HEALTHCARE_DW.INTERMEDIATE.int_claim_with_provider
  
  
  
  
  as (
    

with claims as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_claims
),

providers as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_provider_with_facility
),

plans as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_insurance_plans
),

status_codes as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_claim_status_codes
),

joined as (
    select
        c.claim_id,
        c.claim_number,
        c.patient_id,
        c.medical_record_number,
        c.encounter_id,
        c.encounter_number,
        c.provider_id,
        pr.provider_name,
        pr.specialty_name,
        c.facility_id,
        pr.facility_name,
        pr.facility_type_name,
        c.carrier_id,
        c.plan_id,
        pl.plan_name,
        pl.plan_type,
        pl.deductible_tier,
        c.service_date,
        c.submission_date,
        c.days_to_submit,
        c.total_charge_amount,
        c.total_allowed_amount,
        c.total_paid_amount,
        c.outstanding_balance,
        c.patient_responsibility,
        c.payment_ratio_pct,
        c.current_status_code,
        sc.status_name,
        sc.is_terminal,
        c.primary_diagnosis,
        c.claim_type,
        c.is_clean_claim,
        c.filing_indicator
    from claims c
    left join providers pr     on c.provider_id = pr.provider_id
    left join plans pl         on c.plan_id     = pl.plan_id
    left join status_codes sc  on c.current_status_code = sc.status_code
)

select * from joined
  );

