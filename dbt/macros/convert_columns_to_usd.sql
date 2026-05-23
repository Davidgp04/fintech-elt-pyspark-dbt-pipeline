{% macro convert_columns_to_usd(column, currency_column) %}
    case 
        when {{currency_column}} = 'USD' then {{column}}
        when {{currency_column}} = 'CLP' then {{column}} * 0.0011
        when {{currency_column}} = 'BRL' then {{column}} * 0.2
        when {{currency_column}} = 'PEN' then {{column}} * 0.29
        when {{currency_column}} = 'MXN' then {{column}} * 0.058
        when {{currency_column}} = 'UYU' then {{column}} * 0.025
        when {{currency_column}} = 'ARS' then {{column}} * 0.00071
        when {{currency_column}} = 'COP' then {{column}} * 0.00027
        else null
    end
{% endmacro %}