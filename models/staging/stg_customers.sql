--stg_customers
select
    customer_id,
    trim(first_name)                                as first_name,
    trim(last_name)                                 as last_name,
    lower(trim(email))                              as email,
    trim(phone)                                     as phone,
    initcap(trim(country))                          as country,
    try_to_date(signup_date, 'YYYY-MM-DD')          as signup_date,
    case
        when upper(trim(is_active)) in ('Y','1') then true
        else false
    end                                             as is_active
from {{ source('raw', 'RAW_CUSTOMERS') }}
where trim(email) like '%@%.%'
  and upper(trim(first_name)) != 'TEST'