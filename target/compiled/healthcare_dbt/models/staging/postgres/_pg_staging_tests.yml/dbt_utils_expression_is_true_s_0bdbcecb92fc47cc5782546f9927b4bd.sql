



select
    1
from HEALTHCARE_DW.STAGING.stg_pg_patients

where not(age >= 0 and age <= 120)

