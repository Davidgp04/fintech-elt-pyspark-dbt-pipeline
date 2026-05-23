{{config(materialized='table')}}

select
l.loan_id,
l.customer_id,
d.date_sk,
l.currency ,
l.principal as loan_amount_original,
{{ convert_columns_to_usd('principal', 'currency') }} as loan_amount,
l.term_months,
l.outstanding_balance as original_outstanding_balance,
{{ convert_columns_to_usd('outstanding_balance', 'currency') }} as outstanding_balance,
l.annual_interest_rate,
l.monthly_payment as original_monthly_payment,
{{ convert_columns_to_usd('monthly_payment', 'currency') }} as monthly_payment,
l.type,
l.status,
l.days_past_due
from {{ ref('loans') }} l
left join {{ ref('dim_dates') }} d
    on d.date_day = l.start_date::date