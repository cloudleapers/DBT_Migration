{{config(materialized='view')}}
select * from {{ source('raw', 'RAW_ORDERS') }}