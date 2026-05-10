
    
    

select
    payment_key as unique_field,
    count(*) as n_records

from HEALTHCARE_DW.MART.fct_payment
where payment_key is not null
group by payment_key
having count(*) > 1


