with source as (

    select *
    from {{ source('raw', 'RAW_CUSTOMERS') }}

),

mod1 as (

    select

        customer_id,

        {{ clean_text('first_name') }} as first_name,

        {{ clean_text('last_name') }} as last_name,

        {{ validate_email('email') }} as email,

        trim(phone) as phone,

        {{ clean_text('country') }} as country,

        {{ safe_date('signup_date') }} as signup_date,

        {{ convert_boolean('is_active') }} as is_active,

        created_at,

        _loaded_at

    from source

)

select *
from mod1
where first_name != 'TEST' and last_name != 'USER'