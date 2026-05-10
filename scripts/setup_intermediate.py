"""
Creates 8 intermediate dbt models that join clinical and financial data.
"""
from pathlib import Path

PROJECT_ROOT = Path(r"C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt")
INT_PATH = PROJECT_ROOT / "models" / "intermediate"
INT_PATH.mkdir(parents=True, exist_ok=True)

MODELS = {
    "int_patient_demographics.sql": """{{ config(materialized='view') }}

with patients as (
    select * from {{ ref('stg_pg_patients') }}
),

states as (
    select * from {{ ref('stg_pg_states') }}
),

joined as (
    select
        p.patient_id,
        p.medical_record_number,
        p.full_name,
        p.first_name,
        p.last_name,
        p.date_of_birth,
        p.age,
        p.gender,
        p.race,
        p.ethnicity,
        p.email,
        p.phone,
        p.street_address,
        p.city,
        p.state_code,
        s.state_name,
        s.region,
        p.zip_code,
        p.primary_provider_id,
        p.is_active,
        p.registered_date,
        case
            when p.age < 18 then 'Pediatric'
            when p.age between 18 and 39 then 'Young Adult'
            when p.age between 40 and 64 then 'Adult'
            else 'Senior'
        end                                             as age_group,
        case
            when p.age >= 65 then true
            else false
        end                                             as is_senior,
        case
            when p.age < 18 then true
            else false
        end                                             as is_pediatric
    from patients p
    left join states s on p.state_code = s.state_code
)

select * from joined
""",

    "int_provider_with_facility.sql": """{{ config(materialized='view') }}

with providers as (
    select * from {{ ref('stg_pg_providers') }}
),

specialties as (
    select * from {{ ref('stg_pg_specialty_types') }}
),

facilities as (
    select * from {{ ref('stg_pg_facilities') }}
),

facility_types as (
    select * from {{ ref('stg_pg_facility_types') }}
),

joined as (
    select
        pr.provider_id,
        pr.npi_number,
        pr.first_name                                   as provider_first_name,
        pr.last_name                                    as provider_last_name,
        pr.full_name                                    as provider_name,
        s.specialty_id,
        s.specialty_name,
        f.facility_id,
        f.facility_name,
        ft.facility_type_name,
        f.city                                          as facility_city,
        f.state_code                                    as facility_state,
        pr.license_number,
        pr.hire_date,
        pr.tenure_years,
        pr.is_active,
        pr.email                                        as provider_email,
        pr.phone                                        as provider_phone
    from providers pr
    left join specialties s     on pr.specialty_id = s.specialty_id
    left join facilities f      on pr.facility_id = f.facility_id
    left join facility_types ft on f.facility_type_id = ft.facility_type_id
)

select * from joined
""",

    "int_encounter_full.sql": """{{ config(materialized='view') }}

with encounters as (
    select * from {{ ref('stg_pg_encounters') }}
),

diagnoses as (
    select
        encounter_id,
        count(distinct icd10_code)                      as total_diagnoses,
        count(distinct case when diagnosis_type = 'Primary' then icd10_code end) as primary_diagnoses,
        listagg(icd10_code, '|') within group (order by icd10_code) as all_icd10_codes,
        max(case when diagnosis_type = 'Primary' then icd10_code end) as primary_icd10_code
    from {{ ref('stg_pg_encounter_diagnoses') }}
    group by encounter_id
),

procedures as (
    select
        encounter_id,
        count(distinct cpt_code)                        as total_procedures,
        sum(charge_amount)                              as total_procedure_charges,
        listagg(cpt_code, '|') within group (order by cpt_code) as all_cpt_codes
    from {{ ref('stg_pg_encounter_procedures') }}
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
        e.encounter_time,
        e.duration_minutes,
        e.chief_complaint,
        e.encounter_status,
        e.is_acute_visit,
        coalesce(d.total_diagnoses, 0)                  as total_diagnoses,
        coalesce(d.primary_diagnoses, 0)                as primary_diagnoses,
        d.primary_icd10_code,
        d.all_icd10_codes,
        coalesce(p.total_procedures, 0)                 as total_procedures,
        coalesce(p.total_procedure_charges, 0)          as total_procedure_charges,
        p.all_cpt_codes
    from encounters e
    left join diagnoses d  on e.encounter_id = d.encounter_id
    left join procedures p on e.encounter_id = p.encounter_id
)

select * from joined
""",

    "int_claim_with_provider.sql": """{{ config(materialized='view') }}

with claims as (
    select * from {{ ref('stg_mysql_claims') }}
),

providers as (
    select * from {{ ref('int_provider_with_facility') }}
),

plans as (
    select * from {{ ref('stg_mysql_insurance_plans') }}
),

status_codes as (
    select * from {{ ref('stg_mysql_claim_status_codes') }}
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
""",

    "int_claim_financials.sql": """{{ config(materialized='view') }}

with claims as (
    select * from {{ ref('stg_mysql_claims') }}
),

payments as (
    select
        claim_id,
        count(*)                                        as payment_count,
        sum(payment_amount)                             as total_payment_received,
        min(payment_date)                               as first_payment_date,
        max(payment_date)                               as last_payment_date,
        max(case when payment_method = 'EFT' then 1 else 0 end) as has_eft_payment,
        max(case when payment_method = 'Check' then 1 else 0 end) as has_check_payment
    from {{ ref('stg_mysql_payments') }}
    where is_posted = true
    group by claim_id
),

adjustments as (
    select
        claim_id,
        count(*)                                        as adjustment_count,
        sum(adjustment_amount)                          as total_adjustments,
        max(case when adjustment_code in ('CO-50','CO-167') then 1 else 0 end) as has_medical_necessity_denial,
        max(case when adjustment_code in ('CO-4','CO-11','CO-151') then 1 else 0 end) as has_coding_issue
    from {{ ref('stg_mysql_adjustments') }}
    group by claim_id
),

joined as (
    select
        c.claim_id,
        c.claim_number,
        c.total_charge_amount,
        c.total_allowed_amount,
        c.total_paid_amount,
        c.outstanding_balance,
        c.patient_responsibility,
        c.payment_ratio_pct,
        coalesce(p.payment_count, 0)                    as payment_count,
        coalesce(p.total_payment_received, 0)           as total_payment_received,
        p.first_payment_date,
        p.last_payment_date,
        coalesce(p.has_eft_payment, 0)::boolean         as has_eft_payment,
        coalesce(p.has_check_payment, 0)::boolean       as has_check_payment,
        coalesce(a.adjustment_count, 0)                 as adjustment_count,
        coalesce(a.total_adjustments, 0)                as total_adjustments,
        coalesce(a.has_medical_necessity_denial, 0)::boolean as has_medical_necessity_denial,
        coalesce(a.has_coding_issue, 0)::boolean        as has_coding_issue,
        case
            when c.total_paid_amount = 0 and c.current_status_code = 'DENIED' then 'Fully Denied'
            when c.total_paid_amount = 0 then 'Unpaid'
            when c.total_paid_amount >= c.total_charge_amount * 0.95 then 'Fully Paid'
            when c.total_paid_amount > 0 then 'Partially Paid'
            else 'Unknown'
        end                                             as payment_status_category
    from claims c
    left join payments p    on c.claim_id = p.claim_id
    left join adjustments a on c.claim_id = a.claim_id
)

select * from joined
""",

    "int_encounter_with_claim.sql": """{{ config(materialized='view') }}

with encounters as (
    select * from {{ ref('int_encounter_full') }}
),

claims as (
    select * from {{ ref('int_claim_with_provider') }}
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
""",

    "int_payment_reconciliation.sql": """{{ config(materialized='view') }}

with payments as (
    select * from {{ ref('stg_mysql_payments') }}
),

remittance as (
    select * from {{ ref('stg_mysql_remittance_advice') }}
),

claims as (
    select * from {{ ref('stg_mysql_claims') }}
),

joined as (
    select
        p.payment_id,
        p.claim_id,
        c.claim_number,
        p.payment_number,
        p.carrier_id,
        c.total_charge_amount                           as claim_charge,
        c.total_allowed_amount                          as claim_allowed,
        p.payment_amount,
        c.total_charge_amount - p.payment_amount        as variance_from_charge,
        c.total_allowed_amount - p.payment_amount       as variance_from_allowed,
        p.payment_date,
        p.payment_method,
        p.check_number,
        p.era_number,
        p.is_posted,
        p.posted_date,
        p.days_to_post,
        r.remittance_id,
        r.remittance_date,
        r.total_adjustment                              as remittance_adjustment,
        case
            when p.payment_amount = 0 then 'Zero Payment'
            when p.payment_amount = c.total_charge_amount then 'Fully Paid'
            when p.payment_amount > c.total_charge_amount then 'Overpayment'
            when p.payment_amount < c.total_charge_amount * 0.5 then 'Underpaid Significantly'
            else 'Partial Payment'
        end                                             as reconciliation_status
    from payments p
    left join claims c     on p.claim_id = c.claim_id
    left join remittance r on p.claim_id = r.claim_id
)

select * from joined
""",

    "int_chronic_patients.sql": """{{ config(materialized='view') }}

with diagnoses as (
    select * from {{ ref('stg_pg_encounter_diagnoses') }}
),

icd_codes as (
    select * from {{ ref('stg_pg_icd10_codes') }}
),

encounters as (
    select * from {{ ref('stg_pg_encounters') }}
),

patient_chronic as (
    select
        e.patient_id,
        count(distinct case when ic.is_chronic = true then ic.icd10_code end) as chronic_condition_count,
        listagg(distinct case when ic.is_chronic = true then ic.diagnosis_description end, '; ')
            within group (order by ic.diagnosis_description) as chronic_conditions_list,
        max(d.diagnosed_date)                           as most_recent_chronic_dx
    from encounters e
    join diagnoses d  on e.encounter_id = d.encounter_id
    join icd_codes ic on d.icd10_code   = ic.icd10_code
    group by e.patient_id
),

categorized as (
    select
        patient_id,
        chronic_condition_count,
        chronic_conditions_list,
        most_recent_chronic_dx,
        case
            when chronic_condition_count = 0 then 'Healthy'
            when chronic_condition_count = 1 then 'Single Chronic'
            when chronic_condition_count between 2 and 3 then 'Multi-Chronic'
            else 'High Complexity'
        end                                             as chronic_category,
        case
            when chronic_condition_count >= 2 then true
            else false
        end                                             as is_chronic_patient
    from patient_chronic
)

select * from categorized
""",
}

# Write all model files
for filename, content in MODELS.items():
    file_path = INT_PATH / filename
    file_path.write_text(content, encoding="utf-8", newline="\n")
    print(f"  Created: {filename}")

print(f"\n{len(MODELS)} intermediate models created in:")
print(f"  {INT_PATH}")