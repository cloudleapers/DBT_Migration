 {# {{config(schema = 'RAW')}} #}
 
select * from {{source('raw', 'RAW_ORDERS')}}