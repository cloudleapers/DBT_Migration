{% macro clean_text(column_name) %}
    trim({{column_name}})
{% endmacro %}    

{% macro upper_trim(column_name) %}
    upper(trim({{column_name}}))
{% endmacro %}  

--used only in stg_customers.sql