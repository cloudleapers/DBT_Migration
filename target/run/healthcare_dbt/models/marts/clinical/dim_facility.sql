
  
    

create or replace transient table HEALTHCARE_DW.MART.dim_facility
    
    
    
    as (

with facilities as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_facilities
),

facility_types as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_facility_types
),

states as (
    select * from HEALTHCARE_DW.STAGING.stg_pg_states
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
    )
;


  