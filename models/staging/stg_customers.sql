{{ config(
    materialized='view'
) }}

select
    customer_id,

    {{ replace_na(clean_text('first_name')) }} as first_name,

    {{ clean_text('last_name') }} as last_name,

    {{ clean_email('email') }} as email,

    {{ replace_na("trim(phone)") }} as phone,

    {{ standardize_country('country') }} as country,

    {{ parse_date('signup_date') }} as registration_date,

    {{ boolean_flag('is_active') }} as is_active,

    created_at

from {{ source('raw', 'raw_customers') }}

where customer_id is not null
    and email like '%@%.%'

qualify row_number() over (
    partition by {{ clean_email('email') }}
    order by created_at desc
) = 1