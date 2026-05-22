{{config(materialized='table')}}

with base_cleaned as (
    select *,
        lower(trim(s.account_type)) as account_type_cleaned,
        cast(s.credit_limit as decimal(18, 2)) as credit_limit_cleaned,
        cast(s.interest_rate as decimal(4, 2)) as interest_rate_cleaned,
        case
            when s.opened_date like '__-__-____' then to_date(s.opened_date, 'MM-DD-YYYY')
            when s.opened_date like '____-__-__' then to_date(s.opened_date, 'YYYY-MM-DD')
            when s.opened_date like '__/__/____' then to_date(s.opened_date, 'DD/MM/YYYY')
            when s.opened_date like '________' then to_date(s.opened_date, 'YYYYMMDD')
        end as opened_date_cleaned,
        case
            when lower(trim(s.status)) = 'activo' then 'active'
            when lower(trim(s.status)) = 'congelado' then 'frozen'
            when lower(trim(s.status)) = 'cerrado' then 'closed'
            else lower(trim(s.status))
        end as status_cleaned,
        case 
            when s.balance is null then null
            else cast(s.balance as decimal(18, 2))
        end as balance_cleaned,
        upper(trim(s.branch_code)) as branch_code_cleaned,
        upper(trim(s.currency)) as currency_cleaned

    from {{ source('silver', 'stg_accounts') }} s
)

select 
    c.account_id,  
    c.customer_id,
    c.account_type_cleaned as account_type,
    c.credit_limit_cleaned as credit_limit,
    c.interest_rate_cleaned as interest_rate,
    c.opened_date_cleaned as opened_date,
    c.status_cleaned as status,
    c.branch_code_cleaned as branch_code,
    c.balance_cleaned as balance,
    c.currency_cleaned as currency
from base_cleaned c