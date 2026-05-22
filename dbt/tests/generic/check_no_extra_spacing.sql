{% test check_no_extra_spacing(model, column_name) %}
select * from {{ model }}
where length({{ column_name }}) != length(regexp_replace(trim({{ column_name }}), '\s+', ' ', 'g'))
{% endtest %}


