

with encounters as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_encounters
),

diagnoses as (
    select
        encounter_id,
        count(distinct icd10_code)                      as total_diagnoses,
        count(distinct case when diagnosis_type = 'Primary' then icd10_code end) as primary_diagnoses,
        listagg(icd10_code, '|') within group (order by icd10_code) as all_icd10_codes,
        max(case when diagnosis_type = 'Primary' then icd10_code end) as primary_icd10_code
    from HEALTHCARE_DW.STAGING.stg_pg_encounter_diagnoses
    group by encounter_id
),

procedures as (
    select
        encounter_id,
        count(distinct cpt_code)                        as total_procedures,
        sum(charge_amount)                              as total_procedure_charges,
        listagg(cpt_code, '|') within group (order by cpt_code) as all_cpt_codes
    from HEALTHCARE_DW.STAGING.stg_pg_encounter_procedures
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