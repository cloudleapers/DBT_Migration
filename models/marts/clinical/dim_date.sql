{{ config(materialized='table') }}

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
