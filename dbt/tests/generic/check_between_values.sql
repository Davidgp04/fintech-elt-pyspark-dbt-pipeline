{% test check_between_values(model, column_name, min, max) %}
select * from {{ model }}
where {{ column_name }} < {{ min }} or {{ column_name }} > {{ max }}
{% endtest %}