"""
Creates Mart layer dimensions and facts (star schema).
"""
from pathlib import Path

PROJECT_ROOT = Path(r"C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt")
CLINICAL_PATH = PROJECT_ROOT / "models" / "marts" / "clinical"
FINANCIAL_PATH = PROJECT_ROOT / "models" / "marts" / "financial"
CLINICAL_PATH.mkdir(parents=True, exist_ok=True)
FINANCIAL_PATH.mkdir(parents=True, exist_ok=True)

CLINICAL_MODELS = {
    "dim_patient.sql": """{{ config(materialized='table') }}

with patients as (
    select * from {{ ref('int_patient_demographics') }}
),

chronic as (
    select * from {{ ref('int_chronic_patients') }}
),

final as (
    select
        p.patient_id                                    as patient_key,
        p.medical_record_number,
        p.full_name                                     as patient_name,
        p.first_name,
        p.last_name,
        p.date_of_birth,
        p.age,
        p.age_group,
        p.gender,
        p.race,
        p.ethnicity,
        p.email,
        p.phone,
        p.street_address,
        p.city,
        p.state_code,
        p.state_name,
        p.region,
        p.zip_code,
        p.is_senior,
        p.is_pediatric,
        coalesce(c.chronic_condition_count, 0)          as chronic_condition_count,
        c.chronic_conditions_list,
        coalesce(c.chronic_category, 'Healthy')         as chronic_category,
        coalesce(c.is_chronic_patient, false)           as is_chronic_patient,
        c.most_recent_chronic_dx,
        p.primary_provider_id,
        p.is_active,
        p.registered_date,
        current_timestamp()                             as dim_created_at
    from patients p
    left join chronic c on p.patient_id = c.patient_id
)

select * from final
""",

    "dim_provider.sql": """{{ config(materialized='table') }}

with providers as (
    select * from {{ ref('int_provider_with_facility') }}
),

final as (
    select
        provider_id                                     as provider_key,
        npi_number,
        provider_name,
        provider_first_name,
        provider_last_name,
        specialty_id,
        specialty_name,
        facility_id,
        facility_name,
        facility_type_name,
        facility_city,
        facility_state,
        license_number,
        hire_date,
        tenure_years,
        case
            when tenure_years < 5 then 'Junior'
            when tenure_years between 5 and 14 then 'Mid-Level'
            else 'Senior'
        end                                             as experience_level,
        is_active,
        provider_email,
        provider_phone,
        current_timestamp()                             as dim_created_at
    from providers
)

select * from final
""",

    "dim_facility.sql": """{{ config(materialized='table') }}

with facilities as (
    select * from {{ ref('stg_pg_facilities') }}
),

facility_types as (
    select * from {{ ref('stg_pg_facility_types') }}
),

states as (
    select * from {{ ref('stg_pg_states') }}
),

final as (
    select
        f.facility_id                                   as facility_key,
        f.facility_name,
        ft.facility_type_name,
        f.street_address,
        f.city,
        f.state_code,
        s.state_name,
        s.region,
        f.zip_code,
        f.phone,
        f.capacity_beds,
        case
            when f.capacity_beds = 0 then 'Outpatient Only'
            when f.capacity_beds < 100 then 'Small'
            when f.capacity_beds between 100 and 250 then 'Medium'
            else 'Large'
        end                                             as facility_size,
        f.is_active,
        f.opened_date,
        datediff('year', f.opened_date, current_date()) as years_in_operation,
        current_timestamp()                             as dim_created_at
    from facilities f
    left join facility_types ft on f.facility_type_id = ft.facility_type_id
    left join states s          on f.state_code = s.state_code
)

select * from final
""",

    "dim_diagnosis.sql": """{{ config(materialized='table') }}

with icd_codes as (
    select * from {{ ref('stg_pg_icd10_codes') }}
),

final as (
    select
        icd10_code                                      as diagnosis_key,
        diagnosis_description,
        disease_category,
        is_chronic,
        case
            when disease_category in ('Cardiovascular','Endocrine','Respiratory','Renal') then 'High Risk'
            when disease_category in ('Mental','Neurological') then 'Behavioral'
            when disease_category in ('Wellness','Symptoms') then 'Low Acuity'
            else 'Standard'
        end                                             as risk_category,
        current_timestamp()                             as dim_created_at
    from icd_codes
)

select * from final
""",

    "dim_procedure.sql": """{{ config(materialized='table') }}

with cpt as (
    select * from {{ ref('stg_pg_cpt_codes') }}
),

billing as (
    select * from {{ ref('stg_mysql_billing_codes') }}
),

final as (
    select
        coalesce(c.cpt_code, b.billing_code)            as procedure_key,
        coalesce(c.procedure_description, b.code_description) as procedure_description,
        coalesce(c.procedure_category, 'Other')         as procedure_category,
        coalesce(c.base_cost, b.base_charge, 0)         as base_cost,
        coalesce(b.code_type, 'CPT')                    as code_type,
        case
            when coalesce(c.base_cost, b.base_charge, 0) > 5000 then 'High Cost'
            when coalesce(c.base_cost, b.base_charge, 0) > 500 then 'Medium Cost'
            else 'Low Cost'
        end                                             as cost_tier,
        current_timestamp()                             as dim_created_at
    from cpt c
    full outer join billing b on c.cpt_code = b.billing_code
)

select * from final
""",

    "dim_date.sql": """{{ config(materialized='table') }}

with date_spine as (
    {{ dbt.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

final as (
    select
        date_day                                        as date_key,
        date_day                                        as full_date,
        extract(year from date_day)                     as year,
        extract(quarter from date_day)                  as quarter,
        extract(month from date_day)                    as month_number,
        to_char(date_day, 'Mon')                        as month_name,
        extract(week from date_day)                     as week_of_year,
        extract(day from date_day)                      as day_of_month,
        extract(dayofweek from date_day)                as day_of_week,
        to_char(date_day, 'Dy')                         as day_name,
        case
            when extract(dayofweek from date_day) in (0,6) then true
            else false
        end                                             as is_weekend,
        case
            when extract(month from date_day) in (1,2,3) then 'Q1'
            when extract(month from date_day) in (4,5,6) then 'Q2'
            when extract(month from date_day) in (7,8,9) then 'Q3'
            else 'Q4'
        end                                             as quarter_name,
        to_char(date_day, 'YYYY-MM')                    as year_month,
        current_timestamp()                             as dim_created_at
    from date_spine
)

select * from final
""",

    "fct_encounter.sql": """{{ config(materialized='table') }}

with encounters as (
    select * from {{ ref('int_encounter_with_claim') }}
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
""",
}

FINANCIAL_MODELS = {
    "dim_payer.sql": """{{ config(materialized='table') }}

with carriers as (
    select * from {{ ref('stg_pg_insurance_carriers') }}
),

plans as (
    select * from {{ ref('stg_mysql_insurance_plans') }}
),

payer_types as (
    select * from {{ ref('stg_mysql_payer_types') }}
),

final as (
    select
        p.plan_id                                       as payer_key,
        p.plan_code,
        p.plan_name,
        p.plan_type,
        p.deductible_tier,
        p.deductible_amount,
        p.copay_amount,
        p.out_of_pocket_max,
        p.carrier_id,
        c.carrier_name,
        c.carrier_type,
        pt.payer_type_id,
        pt.payer_type_name,
        p.is_active,
        p.effective_date,
        case
            when pt.payer_type_name = 'Medicare' then 'Government'
            when pt.payer_type_name = 'Medicaid' then 'Government'
            when pt.payer_type_name = 'Self-Pay' then 'Patient'
            else 'Commercial'
        end                                             as payer_segment,
        current_timestamp()                             as dim_created_at
    from plans p
    left join carriers c     on p.carrier_id = c.carrier_id
    left join payer_types pt on p.payer_type_id = pt.payer_type_id
)

select * from final
""",

    "fct_claim.sql": """{{ config(materialized='table') }}

with claims as (
    select * from {{ ref('int_claim_with_provider') }}
),

financials as (
    select * from {{ ref('int_claim_financials') }}
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
""",

    "fct_payment.sql": """{{ config(materialized='table') }}

with payments as (
    select * from {{ ref('int_payment_reconciliation') }}
),

final as (
    select
        payment_id                                      as payment_key,
        claim_id                                        as claim_key,
        claim_number,
        payment_number,
        carrier_id                                      as payer_carrier_id,
        payment_date                                    as payment_date_key,
        claim_charge,
        claim_allowed,
        payment_amount,
        variance_from_charge,
        variance_from_allowed,
        payment_method,
        check_number,
        era_number,
        is_posted,
        posted_date                                     as posted_date_key,
        days_to_post,
        remittance_id,
        remittance_date,
        remittance_adjustment,
        reconciliation_status,
        current_timestamp()                             as fct_created_at
    from payments
)

select * from final
""",
}

for filename, content in CLINICAL_MODELS.items():
    file_path = CLINICAL_PATH / filename
    file_path.write_text(content, encoding="utf-8", newline="\n")
    print(f"  Created clinical: {filename}")

for filename, content in FINANCIAL_MODELS.items():
    file_path = FINANCIAL_PATH / filename
    file_path.write_text(content, encoding="utf-8", newline="\n")
    print(f"  Created financial: {filename}")

print(f"\n{len(CLINICAL_MODELS) + len(FINANCIAL_MODELS)} mart models created")
print(f"  Clinical: {CLINICAL_PATH}")
print(f"  Financial: {FINANCIAL_PATH}")