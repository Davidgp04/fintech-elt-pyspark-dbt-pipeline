{{config (materialized='table')}}

with monthly_interest_rate as (
    select
        *,
        case
            when interest_rate is not null then interest_rate / 100 / 12
            else null
        end as monthly_interest_rate
    from {{ source('silver', 'stg_loans') }}
),

base_cleaned as (
    select *,
    trim(lower(s.type)) as type_cleaned,
    upper(trim(s.currency)) as currency_cleaned,
    case
        when s.principal is null and s.monthly_payment is not null and s.monthly_interest_rate is not null and s.term_months is not null then
            s.monthly_payment * ((1+s.monthly_interest_rate)^s.term_months - 1) / (s.monthly_interest_rate * (1+s.monthly_interest_rate)^s.term_months)
        else s.principal
    end as principal_cleaned,
    cast(s.outstanding_balance as decimal(18, 2)) as outstanding_balance_cleaned,
    cast(s.interest_rate as decimal(4, 2)) as interest_rate_cleaned,
    term_months::integer as term_months_cleaned,
    case
        when s.monthly_payment is null and s.principal is not null and s.monthly_interest_rate is not null and s.term_months is not null then
            s.principal * (s.monthly_interest_rate * (1 + s.monthly_interest_rate)^s.term_months) / ((1 + s.monthly_interest_rate)^s.term_months - 1)
        else s.monthly_payment
    end as monthly_payment_cleaned,
    case
        when s.start_date like '____-__-__' then to_date(s.start_date, 'YYYY-MM-DD')
        when s.start_date like '__-__-____' then to_date(s.start_date, 'MM-DD-YYYY')
        when s.start_date like '__/__/____' then to_date(s.start_date, 'DD/MM/YYYY')
        when s.start_date like '________' then to_date(s.start_date, 'YYYYMMDD')
    end as start_date_cleaned,
    case
        when s.end_date like '____-__-__' then to_date(s.end_date, 'YYYY-MM-DD')
        when s.end_date like '__-__-____' then to_date(s.end_date, 'MM-DD-YYYY')
        when s.end_date like '__/__/____' then to_date(s.end_date, 'DD/MM/YYYY')
        when s.end_date like '________' then to_date(s.end_date, 'YYYYMMDD')
    end as end_date_cleaned,
    lower(trim(s.status)) as status_cleaned,
    days_past_due::integer as days_past_due_cleaned,
    case
        when lower(trim(s.collateral_type)) in ('none', 'null', '', 'n/a', 'na') then null
        else lower(trim(regexp_replace(s.collateral_type, '\s+', '', 'g')))
    end as collateral_type_cleaned

    from monthly_interest_rate s
)

select
    l.loan_id,
    l.customer_id,
    l.currency_cleaned as currency,
    cast(l.principal_cleaned as decimal(18, 2)) as principal,
    l.outstanding_balance_cleaned as outstanding_balance,
    l.interest_rate_cleaned as annual_interest_rate,
    l.term_months_cleaned as term_months,
    l.monthly_payment_cleaned as monthly_payment,
    l.start_date_cleaned as start_date,
    l.end_date_cleaned as end_date,
    l.status_cleaned as status,
    l.days_past_due_cleaned as days_past_due,
    l.collateral_type_cleaned as collateral_type,
    l.type_cleaned as type



    from base_cleaned l