{% test check_no_leading_trailing_spaces(model, column_name) %}
select * from {{ model }}
where {{ column_name }} != trim({{ column_name }})
{% endtest %}