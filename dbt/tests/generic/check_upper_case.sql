{%test check_upper_case (model, column_name)%}
select * from {{model}}
where {{column_name}} != upper({{column_name}})
{%endtest%}