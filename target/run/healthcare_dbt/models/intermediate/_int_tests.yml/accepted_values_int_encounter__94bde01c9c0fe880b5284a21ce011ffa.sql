
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        collection_status as value_field,
        count(*) as n_records

    from HEALTHCARE_DW.INTERMEDIATE.int_encounter_with_claim
    group by collection_status

)

select *
from all_values
where value_field not in (
    'No Claim Filed','Unpaid','Fully Collected','Partially Collected'
)



  
  
      
    ) dbt_internal_test