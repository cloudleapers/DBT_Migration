-- tests/assert_positive_order_amount.sql
select
    order_id,
    net_amount,
    gross_amount,
    discount_amount,
    'net_amount must be > 0' as failure_reason
from {{ ref('fct_orders') }}
where net_amount <= 0

union all

select
    order_id,
    net_amount,
    gross_amount,
    discount_amount,
    'gross_amount must be > 0' as failure_reason
from {{ ref('fct_orders') }}
where gross_amount <= 0

union all

select
    order_id,
    net_amount,
    gross_amount,
    discount_amount,
    'discount_amount must be >= 0' as failure_reason
from {{ ref('fct_orders') }}
where discount_amount < 0
