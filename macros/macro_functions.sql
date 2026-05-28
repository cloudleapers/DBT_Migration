{% macro clean_email(column_name) %}

lower(
    regexp_replace(                              
        regexp_replace(                          
            regexp_replace(                       
                regexp_replace(                   
                    regexp_replace(             
                        trim({{ column_name }}),
                        '\\s+',
                        ''
                    ),
                    '@+',
                    '@'
                ),
                '\\.+@',
                '@'
            ),
            '[^a-zA-Z0-9]+$',
            ''
        ),
        '^[^a-zA-Z0-9]+',
        ''
    )
)

{% endmacro %}

{% macro generate_schema_name(custom_schema_name, node) %}

    {% if custom_schema_name is none %}
        {{ target.schema }}
    {% else %}
        {{ custom_schema_name }}
    {% endif %}

{% endmacro %}

{% macro not_null(column_name) %}
    {{ column_name }} is not null
{% endmacro %}

{% macro upper_trim(column_name) %}
    upper(trim({{ column_name }}))
{% endmacro %}

{% macro lower_trim(column_name) %}
    upper(trim({{ column_name }}))
{% endmacro %}

{% macro plain_trim(column_name) %}
    trim({{ column_name }})
{% endmacro %}

{% macro status_fun(column_name) %}
    case
        when upper(trim({{ column_name }})) in ('Y','1')
            then 'True'
        when upper(trim({{ column_name }})) in ('N','0')
            then 'False'
        else 'N/A'
    end
{% endmacro %}

{% macro update_snapshot_active(snapshot_table) %}

    update {{ snapshot_table }}
    set is_active = 'NO'
    where dbt_valid_to is not null;

    update {{ snapshot_table }}
    set is_active = 'YES'
    where dbt_valid_to is null;

{% endmacro %}

