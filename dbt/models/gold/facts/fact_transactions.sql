{{config(materialized='table')}}

select
t.transaction_id,
t.account_id,
a.customer_id,
d.date_sk,
t.amount,
t.type,
t.status,
t.category,
t.currency,
t.merchant,
t.channel
from {{ ref('transactions') }} t
left join {{ ref('dim_dates') }} d
    on d.date_day = t.date::date
left join {{ref('dim_accounts') }} a
    on t.account_id = a.account_id