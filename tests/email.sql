select
    email,
    count(*) as cnt
from {{ ref('stg_customers') }}
group by email
having count(*) > 1