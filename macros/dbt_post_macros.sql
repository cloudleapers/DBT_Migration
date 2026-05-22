
{% macro clean_text(column_name) %}
    initcap(trim({{ column_name }}))
{% endmacro %}

{% macro replace_na(column_name) %}
coalesce({{ column_name }}, 'N/A')
{% endmacro %}

{% macro clean_email(column_name) %}
lower(trim(replace({{ column_name }}, '@@', '@')))
{% endmacro %}

{% macro standardize_country(column_name) %}
    case
        when upper(trim({{ column_name }})) in ('USA', 'US', 'U') then 'USA'
        when upper(trim({{ column_name }})) = 'UK' then 'UK'
        else initcap(trim({{ column_name }}))
    end
{% endmacro %}

{% macro parse_date(column_name) %}
    coalesce(
        try_to_date(trim({{ column_name }})::varchar, 'YYYY-MM-DD'),
        try_to_date(trim({{ column_name }})::varchar, 'YYYY/MM/DD'),
        try_to_date(trim({{ column_name }})::varchar, 'DD-MM-YYYY')
    )
{% endmacro %}

{% macro boolean_flag(column_name) %}
    case
        when upper(trim({{ column_name }})) in ('Y', '1') then True
        else False
    end
{% endmacro %}

{% macro margin_pct(unit_price, cost_price) %}
    round(
        ({{ unit_price }} - {{ cost_price }})
        / nullif({{ unit_price }}, 0) * 100,
        2
    )
{% endmacro %}


{% macro gross_amount(quantity, unit_price) %}
    round(
        {{ quantity }} * {{ unit_price }},
        2
    )
{% endmacro %}

{% macro discount_amount(quantity, unit_price, discount_pct) %}
    round(
        {{ quantity }} * {{ unit_price }} * {{ discount_pct }} / 100,
        2
    )
{% endmacro %}


{% macro net_amount(quantity, unit_price, discount_pct) %}
    round(
        {{ quantity }} * {{ unit_price }} * (1 - {{ discount_pct }} / 100),
        2
    )
{% endmacro %}