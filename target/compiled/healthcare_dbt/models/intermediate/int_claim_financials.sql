

with claims as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_claims
),

payments as (
    select
        claim_id,
        count(*)                                        as payment_count,
        sum(payment_amount)                             as total_payment_received,
        min(payment_date)                               as first_payment_date,
        max(payment_date)                               as last_payment_date,
        max(case when payment_method = 'EFT' then 1 else 0 end) as has_eft_payment,
        max(case when payment_method = 'Check' then 1 else 0 end) as has_check_payment
    from HEALTHCARE_DW.STAGING.stg_mysql_payments
    where is_posted = true
    group by claim_id
),

adjustments as (
    select
        claim_id,
        count(*)                                        as adjustment_count,
        sum(adjustment_amount)                          as total_adjustments,
        max(case when adjustment_code in ('CO-50','CO-167') then 1 else 0 end) as has_medical_necessity_denial,
        max(case when adjustment_code in ('CO-4','CO-11','CO-151') then 1 else 0 end) as has_coding_issue
    from HEALTHCARE_DW.STAGING.stg_mysql_adjustments
    group by claim_id
),

joined as (
    select
        c.claim_id,
        c.claim_number,
        c.total_charge_amount,
        c.total_allowed_amount,
        c.total_paid_amount,
        c.outstanding_balance,
        c.patient_responsibility,
        c.payment_ratio_pct,
        coalesce(p.payment_count, 0)                    as payment_count,
        coalesce(p.total_payment_received, 0)           as total_payment_received,
        p.first_payment_date,
        p.last_payment_date,
        coalesce(p.has_eft_payment, 0)::boolean         as has_eft_payment,
        coalesce(p.has_check_payment, 0)::boolean       as has_check_payment,
        coalesce(a.adjustment_count, 0)                 as adjustment_count,
        coalesce(a.total_adjustments, 0)                as total_adjustments,
        coalesce(a.has_medical_necessity_denial, 0)::boolean as has_medical_necessity_denial,
        coalesce(a.has_coding_issue, 0)::boolean        as has_coding_issue,
        case
            when c.total_paid_amount = 0 and c.current_status_code = 'DENIED' then 'Fully Denied'
            when c.total_paid_amount = 0 then 'Unpaid'
            when c.total_paid_amount >= c.total_charge_amount * 0.95 then 'Fully Paid'
            when c.total_paid_amount > 0 then 'Partially Paid'
            else 'Unknown'
        end                                             as payment_status_category
    from claims c
    left join payments p    on c.claim_id = p.claim_id
    left join adjustments a on c.claim_id = a.claim_id
)

select * from joined