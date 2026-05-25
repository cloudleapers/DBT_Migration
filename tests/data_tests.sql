select * from {{ source('stg', 'stg_customers')}}
where
    customer_id is null
    or email not like '%@%.%'
