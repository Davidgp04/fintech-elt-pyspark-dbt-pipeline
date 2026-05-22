{{config(materialized='table')}}

-- Dimension table for accounts
select 
    account_id,
    customer_id,
    account_type,
    currency,
    status,
    opened_date,
    balance
from {{ ref('accounts') }}