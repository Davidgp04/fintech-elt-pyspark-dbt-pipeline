{{config(materialized='table')}}

select
l.loan_id,
l.customer_id,
d.date_sk,
l.principal as loan_amount,
l.outstanding_balance,
l.annual_interest_rate,
l.monthly_payment,
l.type,
l.status,
l.days_past_due
from {{ ref('loans') }} l
left join {{ ref('dim_dates') }} d
    on d.date_day = l.start_date::date