

with date_spine as (
    


    


    with rawdata as (

        

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * power(2, 0)
     + 
    
    p1.generated_number * power(2, 1)
     + 
    
    p2.generated_number * power(2, 2)
     + 
    
    p3.generated_number * power(2, 3)
     + 
    
    p4.generated_number * power(2, 4)
     + 
    
    p5.generated_number * power(2, 5)
     + 
    
    p6.generated_number * power(2, 6)
     + 
    
    p7.generated_number * power(2, 7)
     + 
    
    p8.generated_number * power(2, 8)
     + 
    
    p9.generated_number * power(2, 9)
     + 
    
    p10.generated_number * power(2, 10)
     + 
    
    p11.generated_number * power(2, 11)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
     cross join 
    
    p as p11
    
    

    )

    select *
    from unioned
    where generated_number <= 4017
    order by generated_number



    ),

    all_periods as (

        select (
            

    dateadd(
        day,
        row_number() over (order by 1) - 1,
        cast('2020-01-01' as date)
        )


        ) as date_day
        from rawdata

    ),

    filtered as (

        select *
        from all_periods
        where date_day <= cast('2030-12-31' as date)

    )

    select * from filtered


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