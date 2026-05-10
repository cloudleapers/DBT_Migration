



select
    1
from HEALTHCARE_DW.MART.fct_claim

where not(total_charge_amount >= 0)

