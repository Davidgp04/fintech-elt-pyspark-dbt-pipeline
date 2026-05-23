{{config(materialized='table')}}

select
    customer_id,
    credit_score,
    currency,
    total_used as original_total_used,
    {{ convert_columns_to_usd('total_used', 'currency') }} as total_used
    from {{ref('credit_info')}}