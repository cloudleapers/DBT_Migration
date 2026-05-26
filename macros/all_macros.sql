{% macro clean_text(column_name) %}
    trim(upper({{ column_name }}))
{% endmacro %}


{% macro validate_email(column_name) %}
lower(trim(replace({{ column_name }}, '@@', '@')))
{% endmacro %}


{% macro convert_boolean(column_name) %}

case
    when upper({{ column_name }}) in ('Y','1','TRUE')
    then true
    else false
end

{% endmacro %}

{% macro safe_date(column_name) %}
    try_to_date({{ column_name }})
{% endmacro %}

{% macro to_upper_trim(column_name) %}
    upper(trim({{ column_name }}))
{% endmacro %}

{% macro to_integer(column_name) %}
    try_cast({{ column_name }} as integer)
{% endmacro %}

{% macro to_decimal(column_name, precision=10, scale=2) %}
    try_cast({{ column_name }} as number({{ precision }},{{ scale }}))
{% endmacro %}

{% macro numeric_clean(column_name, precision=10, scale=2) %}
    nullif(
        try_cast({{ column_name }} as number({{ precision }}, {{ scale }})),
        0
    )
{% endmacro %}

{% macro integer_clean(column_name) %}
    nullif(
        try_cast({{ column_name }} as integer),
        0
    )
{% endmacro %} 
