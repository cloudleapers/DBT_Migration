{% macro booleans(column_name) %}
    case
        when upper(trim({{ column_name }})) in ('Y', '1') then true
        else false
    end
{% endmacro %}


{% macro coalesce_to(column_name) %}
    case
        when {{ column_name }} is null or trim({{ column_name }}) = '' then 'N/A'
        else {{ column_name }}
    end
{% endmacro %}


{% macro fix_email(email_column, order_column) %}
    row_number() over (
        partition by lower(trim({{ email_column }}))
        order by {{ order_column }} desc
    )
{% endmacro %}