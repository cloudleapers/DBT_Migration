{% macro clean_text(column_name) %}
    coalesce(trim({{ column_name }}), 'N/A')
{% endmacro %}

{% macro clean_email(column_name) %}
    lower(replace(trim({{ column_name }}), '@@', '@'))
{% endmacro %}

{% macro title_case(column_name) %}
    initcap(trim({{ column_name }}))
{% endmacro %}

{% macro format_date(column_name) %}
    coalesce(
        try_to_date(trim({{ column_name }}), 'YYYY-MM-DD'),
        try_to_date(trim({{ column_name }}), 'YYYY/MM/DD'),
        try_to_date(trim({{ column_name }}), 'DD-MM-YYYY')
    )
{% endmacro %}

{% macro active_status(column_name) %}
    case
        when upper(trim({{ column_name }})) in ('Y','1')
            then 'active'
        when upper(trim({{ column_name }})) in ('N','0')
            then 'inactive'
        else 'N/A'
    end
{% endmacro %}

{% macro positive_value(column_name) %}
    {{ column_name }} > 0
{% endmacro %}

{% macro not_null(column_name) %}
    {{ column_name }} is not null
{% endmacro %}

{% macro valid_range(column_name, min_val, max_val) %}
    {{ column_name }} between {{ min_val }} and {{ max_val }}
{% endmacro %}

{% macro filter(column_name) %}
    upper(trim({{ column_name }}))
{% endmacro %}

{% macro valid_fk(column_name, source_name, table_name, key_column) %}
    {{ column_name }} in (
        select {{ key_column }}
        from {{ source(source_name, table_name) }}
    )
{% endmacro %}