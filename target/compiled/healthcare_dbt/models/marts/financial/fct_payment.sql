

with payments as (
    select * from HEALTHCARE_DW.INTERMEDIATE.int_payment_reconciliation
),

final as (
    select
        payment_id                                      as payment_key,
        claim_id                                        as claim_key,
        claim_number,
        payment_number,
        carrier_id                                      as payer_carrier_id,
        payment_date                                    as payment_date_key,
        claim_charge,
        claim_allowed,
        payment_amount,
        variance_from_charge,
        variance_from_allowed,
        payment_method,
        check_number,
        era_number,
        is_posted,
        posted_date                                     as posted_date_key,
        days_to_post,
        remittance_id,
        remittance_date,
        remittance_adjustment,
        reconciliation_status,
        current_timestamp()                             as fct_created_at
    from payments
)

select * from final