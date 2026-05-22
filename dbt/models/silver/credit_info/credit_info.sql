{{config(materialized='table')}}

with base_cleaned as (
    select *,
    case
        when credit_info::jsonb->>'credit_score' ~ '^[0-9]+$' 
            and (credit_info::jsonb->>'credit_score')::integer between 300 and 850
        then (credit_info::jsonb->>'credit_score')::integer
        else null  -- Invalid scores become NULL
    end as credit_score,
    upper(trim(credit_info::jsonb->>'currency')) as currency,
     case 
        when credit_info::jsonb->>'utilization_pct' is null then null
        when trim(credit_info::jsonb->>'utilization_pct') = '' then null
        else (
            regexp_replace(
                regexp_replace(
                    regexp_replace(trim(credit_info::jsonb->>'utilization_pct'), '[$€£]|USD', '', 'g'),

                    '[A-Za-z]', '', 'g'
                ),
                ',', '.'
            )::float 
        )
        end as utilization_pct_cleaned,
        
    case
        when credit_info::jsonb->>'total_limit' is null then null
        when trim(credit_info::jsonb->>'total_limit') = '' then null
        else (
            regexp_replace(
                regexp_replace(
                    regexp_replace(trim(credit_info::jsonb->>'total_limit'), '[$€£]|USD', '', 'g'),
                    '[A-Za-z]', '', 'g'
                ),
                ',', '.'
            )::float
        )
    end as total_limit_cleaned,
    case
        when credit_info::jsonb->>'total_used' is null then null
        when trim(credit_info::jsonb->>'total_used') = '' then null
        else (
            regexp_replace(
                regexp_replace(
                    regexp_replace(trim(credit_info::jsonb->>'total_used'), '[$€£]|USD', '', 'g'),
                    '[A-Za-z]', '', 'g'
                ),
                ',', '.'
            )::float
        )
    end as total_used_cleaned,
    lower(trim(credit_info::jsonb->>'num_credit_accounts'))::integer as num_credit_accounts,
    lower(trim(credit_info::jsonb->>'oldest_account_age_months'))::integer as oldest_account_age_months,
    lower(trim(credit_info::jsonb->>'late_payments_12m'))::integer as late_payments_12m,
    lower(trim(credit_info::jsonb->>'inquiries_6m'))::integer as inquiries_6m,
    case
        when lower(trim(credit_info::jsonb->>'bankruptcy_flag')) in ('true', '1', 'y') then true
        when lower(trim(credit_info::jsonb->>'bankruptcy_flag')) in ('false', '0', 'n') then false
        else null
    end as bankruptcy_flag_cleaned
    from {{ source('silver', 'stg_customers') }}
)

select
    customer_id,
    credit_score,
    currency,
    utilization_pct_cleaned as utilization_pct,
    total_limit_cleaned as total_limit,
    total_used_cleaned as total_used,
    num_credit_accounts ,
    oldest_account_age_months,
    late_payments_12m,
    inquiries_6m,
    bankruptcy_flag_cleaned as bankruptcy_flag
from base_cleaned