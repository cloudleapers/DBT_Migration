

with diagnoses as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_encounter_diagnoses
),

icd_codes as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_icd10_codes
),

encounters as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_encounters
),

patient_chronic as (
    select
        e.patient_id,
        count(distinct case when ic.is_chronic = true then ic.icd10_code end) as chronic_condition_count,
        listagg(distinct case when ic.is_chronic = true then ic.diagnosis_description end, '; ')
            as chronic_conditions_list,
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