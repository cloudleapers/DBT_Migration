{{ config(materialized='view') }}

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
