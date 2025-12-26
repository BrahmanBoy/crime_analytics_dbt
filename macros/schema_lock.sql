{% macro generate_schema_name(custom_schema_name, node) -%}
  {# 
    Hard-lock all models to ANALYTICS regardless of target.schema or model config.
    Prevents accidental schema duplication like ANALYTICS_ANALYTICS.
  #}
  {{ return('ANALYTICS') }}
{%- endmacro %}
