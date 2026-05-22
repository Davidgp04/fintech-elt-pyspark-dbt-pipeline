{% test check_no_incorrect_date_format(model, column_name) %}
select * from {{ model }}
where {{ column_name }} is not null and {{ column_name }}::text not like '____-__-__'
and ( {{ column_name}} > current_date or {{column_name}} < '1900-01-01' )
{% endtest %}

