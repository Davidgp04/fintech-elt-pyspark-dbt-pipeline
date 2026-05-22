{{config(materialized='table')}}

with base_cleaned as (
    select customer_id,
    digital_engagement::jsonb as digital_engagement_json
    from {{ source('silver', 'stg_customers') }}
)

select
    customer_id,
    (digital_engagement_json->>'mobile_app_registered')::boolean as mobile_app_registered,
    (digital_engagement_json->>'web_banking_registered')::boolean as web_banking_registered,
    case
        when (digital_engagement_json->>'last_login_date')::text like '____-__-__' then to_date(digital_engagement_json->>'last_login_date', 'YYYY-MM-DD')
        when (digital_engagement_json->>'last_login_date')::text like '__-__-____' then to_date(digital_engagement_json->>'last_login_date', 'MM-DD-YYYY')
        when (digital_engagement_json->>'last_login_date')::text like '__/__/____' then to_date(digital_engagement_json->>'last_login_date', 'DD/MM/YYYY')
        when (digital_engagement_json->>'last_login_date')::text like '________' then to_date(digital_engagement_json->>'last_login_date', 'YYYYMMDD')
        else null
    end as last_login_date,
    case
        when trim(digital_engagement_json->>'avg_monthly_logins') ~ '^[0-9]+$' then cast(digital_engagement_json->>'avg_monthly_logins' as integer)
        else null
    end as avg_monthly_logins,
    lower(trim(digital_engagement_json->>'preferred_channel')) as preferred_channel,
    case
        when lower(trim(digital_engagement_json->>'push_notifications')) in ('true', '1', 'yes') then true
        when lower(trim(digital_engagement_json->>'push_notifications')) in ('false', '0', 'no') then false
        else null
    end as push_notifications,
    case
        when lower(trim(digital_engagement_json->>'paperless_statements')) in ('true', '1', 'si') then true
        when lower(trim(digital_engagement_json->>'paperless_statements')) in ('false', '0', 'no') then false
        else null
    end as paperless_statements
from base_cleaned
