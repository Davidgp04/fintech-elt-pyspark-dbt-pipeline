{{ config(materialized='table') }}

with base_cleaned as (
    select *,
    case
        when s.date like '____-__-__' then to_date(s.date, 'YYYY-MM-DD')
        when s.date like '__-__-____' then to_date(s.date, 'MM-DD-YYYY')
        when s.date like '__/__/____' then to_date(s.date, 'DD/MM/YYYY')
        when s.date like '________' then to_date(s.date, 'YYYYMMDD')
    end as date_cleaned,
    case
        when s.amount is null then null
        else cast(s.amount as decimal(18, 2))
    end as amount_cleaned,
    upper(trim(s.currency)) as currency_cleaned,
    case
        when lower(trim(s.type)) = 'retiro' then 'withdrawal'
        when lower(trim(s.type)) = 'transferencia' then 'transfer'
        when lower(trim(s.type)) = 'reembolso' then 'refund'
        when lower(trim(s.type)) = 'pago' then 'payment'
        when lower(trim(s.type)) = 'deposito' then 'deposit'
        when lower(trim(s.type)) = 'comision' then 'fee'
        else lower(trim(s.type))
    end as type_cleaned,
    case
        when lower(trim(s.category)) in ('utilities', 'salary', 'rent', 'entertainment',
        'education', 'insurance', 'groceries', 'shopping', 'subscription', 'transport',
        'dining', 'healthcare', 'travel', 'investment', 'other') then lower(trim(s.category))
        -- when lower(trim(s.category)) in ('none', 'null', '', 'n/a', 'na') then null
        else null
    end as category_cleaned,
    case
        when trim(lower(s.merchant)) in ('none', 'null', '', 'n/a', 'na') then null
        else trim(s.merchant)
    end as merchant_cleaned,
    lower(trim(s.channel)) as channel_cleaned,
    lower(trim(s.status)) as status_cleaned,
    trim(regexp_replace(s.description, '\s+', ' ', 'g')) as description_cleaned
        
from {{ source('silver', 'stg_transactions') }} s
)

select
    t.transaction_id,
    t.account_id,
    t.date_cleaned as date,
    t.amount_cleaned as amount,
    t.currency_cleaned as currency,
    t.type_cleaned as type,
    t.category_cleaned as category,
    t.merchant_cleaned as merchant,
    t.channel_cleaned as channel,
    t.status_cleaned as status,
    t.description_cleaned as description
from base_cleaned t