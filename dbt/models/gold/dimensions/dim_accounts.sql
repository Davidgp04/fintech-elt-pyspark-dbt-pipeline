{{config(materialized='table')}}

-- Dimension table for accounts
select 
    account_id,
    customer_id,
    account_type,
    currency,
    status,
    opened_date,
    balance as orignial_balance,
    {{ convert_columns_to_usd('balance', 'currency') }} as balance
from {{ ref('accounts') }}