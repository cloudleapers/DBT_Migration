
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        reconciliation_status as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.MART.fct_payment
    group by reconciliation_status

)

select *
from all_values
where value_field not in (
    'Zero Payment','Fully Paid','Overpayment','Underpaid Significantly','Partial Payment'
)



  
  
      
    ) dbt_internal_test