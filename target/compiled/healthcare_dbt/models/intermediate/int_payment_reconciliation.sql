

with payments as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_payments
),

remittance as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_remittance_advice
),

claims as (
    select * from HEALTHCARE_DW.STAGING.stg_mysql_claims
),

joined as (
    select
        p.payment_id,
        p.claim_id,
        c.claim_number,
        p.payment_number,
        p.carrier_id,
        c.total_charge_amount                           as claim_charge,
        c.total_allowed_amount                          as claim_allowed,
        p.payment_amount,
        c.total_charge_amount - p.payment_amount        as variance_from_charge,
        c.total_allowed_amount - p.payment_amount       as variance_from_allowed,
        p.payment_date,
        p.payment_method,
        p.check_number,
        p.era_number,
        p.is_posted,
        p.posted_date,
        p.days_to_post,
        r.remittance_id,
        r.remittance_date,
        r.total_adjustment                              as remittance_adjustment,
        case
            when p.payment_amount = 0 then 'Zero Payment'
            when p.payment_amount = c.total_charge_amount then 'Fully Paid'
            when p.payment_amount > c.total_charge_amount then 'Overpayment'
            when p.payment_amount < c.total_charge_amount * 0.5 then 'Underpaid Significantly'
            else 'Partial Payment'
        end                                             as reconciliation_status
    from payments p
    left join claims c     on p.claim_id = c.claim_id
    left join remittance r on p.claim_id = r.claim_id
)

select * from joined