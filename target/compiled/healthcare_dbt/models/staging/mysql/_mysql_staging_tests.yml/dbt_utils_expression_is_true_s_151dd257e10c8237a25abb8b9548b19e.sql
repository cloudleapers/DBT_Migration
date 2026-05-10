



select
    1
from HEALTHCARE_DW.STAGING.stg_mysql_claims

where not(total_charge_amount >= 0)

