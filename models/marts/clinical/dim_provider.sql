{{ config(materialized='table') }}

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
