



select
    1
from HEALTHCARE_DW.STAGING.stg_mysql_payments

where not(payment_amount >= 0)

