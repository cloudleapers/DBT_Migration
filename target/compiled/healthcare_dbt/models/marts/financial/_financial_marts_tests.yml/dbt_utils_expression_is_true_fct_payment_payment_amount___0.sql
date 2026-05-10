



select
    1
from HEALTHCARE_DW.MART.fct_payment

where not(payment_amount >= 0)

