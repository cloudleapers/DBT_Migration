
  create or replace   view HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
  
  
  
  
  as (
    

with encounters as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_encounter_full
),

claims as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_claim_with_provider
),

claim_aggregates as (
    select
        encounter_id,
        count(*)                                        as claims_per_encounter,
        sum(total_charge_amount)                        as total_billed,
        sum(total_paid_amount)                          as total_collected,
        sum(outstanding_balance)                        as total_outstanding,
        max(current_status_code)                        as latest_claim_status,
        max(is_clean_claim::int)::boolean               as had_clean_claim
    from claims
    where encounter_id is not null
    group by encounter_id
),

joined as (
    select
        e.encounter_id,
        e.encounter_number,
        e.patient_id,
        e.provider_id,
        e.facility_id,
        e.encounter_type,
        e.encounter_date,
        e.duration_minutes,
        e.is_acute_visit,
        e.total_diagnoses,
        e.primary_icd10_code,
        e.total_procedures,
        e.total_procedure_charges,
        coalesce(ca.claims_per_encounter, 0)            as claims_per_encounter,
        coalesce(ca.total_billed, 0)                    as total_billed,
        coalesce(ca.total_collected, 0)                 as total_collected,
        coalesce(ca.total_outstanding, 0)               as total_outstanding,
        ca.latest_claim_status,
        coalesce(ca.had_clean_claim, false)             as had_clean_claim,
        case
            when ca.claims_per_encounter is null then 'No Claim Filed'
            when ca.total_collected = 0 then 'Unpaid'
            when ca.total_collected >= ca.total_billed * 0.95 then 'Fully Collected'
            else 'Partially Collected'
        end                                             as collection_status
    from encounters e
    left join claim_aggregates ca on e.encounter_id = ca.encounter_id
)

select * from joined
  );

