{% macro get_metadata_columns() %}
    current_timestamp() as _dbt_loaded_at,
    '{{ invocation_id }}' as _dbt_run_id,
    '{{ this.name }}' as _dbt_source_model
{% endmacro %}