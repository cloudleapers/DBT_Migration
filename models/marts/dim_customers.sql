{{
    config(
        materialized='incremental',
        schema = 'MARTS',

        pre_hook="""
        {% if is_incremental() %}
        update {{ this }} tgt
        set is_active = 'NO'

        from {{ source('stage', 'stg_customers') }} src

        where tgt.customer_id = src.customer_id
          and tgt.is_active = 'YES'

          and (
                tgt.customer_name <> concat(src.first_name,' ',src.last_name)
             or tgt.email <> src.email
             or tgt.phone <> src.phone
             or tgt.country <> src.country
             or tgt.signup_date <> src.signup_date
          )
        {% endif %}
        """
    )
}}

with dim_cust as (

    select
        customer_id,
        concat(first_name,' ',last_name) as customer_name,
        email,
        phone,
        country,
        signup_date,

        'YES' as is_active,
        current_timestamp as created_at

    from {{ source('stage', 'stg_customers') }}

)
{% if is_incremental() %}
,

new_or_changed as (

    select src.*

    from dim_cust src

    left join {{ this }} tgt
        on src.customer_id = tgt.customer_id
       and tgt.is_active = 'YES'

    where tgt.customer_id is null

       or (
            tgt.customer_name <> src.customer_name
         or tgt.email <> src.email
         or tgt.phone <> src.phone
         or tgt.country <> src.country
         or tgt.signup_date <> src.signup_date
       )

)

select *
from new_or_changed
{% else %}

select *
from dim_cust

{% endif %}