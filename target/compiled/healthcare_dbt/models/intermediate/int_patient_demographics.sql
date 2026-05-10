

with patients as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_patients
),

states as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_states
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