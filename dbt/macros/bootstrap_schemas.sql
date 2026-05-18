-- macros/bootstrap_schemas.sql

{% macro bootstrap_schemas() %}

    {% set schemas = ['bronze', 'silver', 'gold', 'raw'] %}

    {% for schema in schemas %}

        {% set sql %}
            create schema if not exists {{ schema }}
        {% endset %}

        {{ log(sql, info=True) }}

        {% do run_query(sql) %}

    {% endfor %}

{% endmacro %}