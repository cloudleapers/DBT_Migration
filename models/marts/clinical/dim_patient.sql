{{ config(materialized='table') }}

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
