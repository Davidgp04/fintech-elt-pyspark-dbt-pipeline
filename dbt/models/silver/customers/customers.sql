{{ config(materialized='table') }}

with canonical as (
    select
        country,
        lower(trim(city)) as city,
        count(*)           as freq
    from {{ source('silver', 'stg_customers') }}
    group by country, lower(trim(city))
),

best_matches as (
    select distinct on (a.country, a.city)
        a.country,
        a.city       as raw_city,
        b.city       as matched_city
    from canonical a
    left join canonical b
        on  a.country = b.country
        and a.city <> b.city
        and b.freq > a.freq
        and (a.city <-> b.city) < 0.72  -- Use distance operator
    order by
        a.country,
        a.city,
        a.city <-> b.city  -- Ascending distance (close matches first)
),

base_cleaned as (
    select
        *,
        upper(trim(c.country)) as country_cleaned,
        initcap(coalesce(bm.matched_city, lower(trim(c.city)))) as city_cleaned,
        initcap(regexp_replace(trim(c.first_name), '\s+', ' ', 'g')) as first_name_cleaned,
        initcap(regexp_replace(trim(c.last_name), '\s+', ' ', 'g')) as last_name_cleaned,
        case 
            when c.email not like '%@%'
            then replace(
                lower(trim(c.email)),
                lower(trim(c.last_name)),
                concat(lower(trim(c.last_name)), '@')
            ) else lower(trim(c.email))
        end as email_cleaned,
        case
            when regexp_replace(c.phone_number, '[^0-9+]', '', 'g') like '+%' then regexp_replace(c.phone_number, '[^0-9+]', '', 'g')
            else concat(
                    '+',
                case c.country
                    when 'AR' then '54'
                    when 'BR' then '55'
                    when 'CL' then '56'
                    when 'CO' then '57'
                    when 'MX' then '52'
                    when 'PE' then '51'
                    when 'UY' then '598'
                end,
                regexp_replace(c.phone_number, '[^0-9]', '', 'g')
            )
        end as phone_number_cleaned,
        case
            when c.date_of_birth like '__-__-____' then to_date(c.date_of_birth, 'MM-DD-YYYY')
            when c.date_of_birth like '____-__-__' then to_date(c.date_of_birth, 'YYYY-MM-DD')
            when c.date_of_birth like '__/__/____' then to_date(c.date_of_birth, 'DD/MM/YYYY')
            when c.date_of_birth like '________' then to_date(c.date_of_birth, 'YYYYMMDD')
        end as date_of_birth_cleaned,
                case 
            when upper(trim(c.gender))='M' then 'M'
            when upper(trim(c.gender))='F' then 'F'
            when lower(trim(c.gender))='other' then 'Other'
            else null
        end as cleaned_gender,
        upper(trim(nationality)) as cleaned_nationality,
        trim(lower(kyc_status)) as kyc_status_cleaned,
        case
            when lower(trim(c.status)) = 'activo' then 'active'
            when lower(trim(c.status)) = 'inactivo' then 'inactive'
            when lower(trim(c.status)) = 'suspendido' then 'suspended'
            when lower(trim(c.status)) = 'cerrado' then 'closed'
            else lower(trim(c.status))
        end as status_cleaned,
        case 
            when c.registration_date like '__-__-____' then to_date(c.registration_date, 'MM-DD-YYYY')
            when c.registration_date like '____-__-__' then to_date(c.registration_date, 'YYYY-MM-DD')
            when c.registration_date like '__/__/____' then to_date(c.registration_date, 'DD/MM/YYYY')
            when c.registration_date like '________' then to_date(c.registration_date, 'YYYYMMDD')
        end as registration_date_cleaned,
        case 
            when lower(trim(c.customer_segment)) = 'banca_privada' then 'private_banking'
            when lower(trim(c.customer_segment)) = 'minorista' then 'retail'
            when lower(trim(c.customer_segment)) = 'pyme' then 'sme'
            else lower(trim(c.customer_segment))
        end as customer_segment_cleaned,       
        case 
            when lower(trim(c.relationship_manager)) in ('null', 'na', 'n/a', 'none', '') then null
            else trim(c.relationship_manager)
        end as relationship_manager_cleaned,
        case
                when address is null then null
                when lower(trim(address)) in (
                    '',
                    'null',
                    'na',
                    'n/a',
                    'none'
                ) then null
                else regexp_replace(trim(address), '\s+', ' ', 'g')
        end as address_cleaned
    from {{ source('silver', 'stg_customers') }} c
    left join best_matches bm
        on lower(trim(c.city)) = bm.raw_city
        and c.country = bm.country
),
cleaned as (
    select
        *,
        replace(c.email_cleaned, ' ', '') as email_cleaned_no_spaces,
        extract(year from age(current_date, c.date_of_birth_cleaned)) as age,
        extract(year from age(current_date, c.registration_date_cleaned::date)) * 12 +
        extract(month from age(current_date, c.registration_date_cleaned::date)) as tenure_months
    from base_cleaned c
),

cleaned_age_bucket_included as(
    select
    *,
    case
        when age < 18 then 'Under 18'
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        when age between 55 and 64 then '55-64'
        when age >= 65 then '65+'
        else 'Unknown'
    end as age_bucketed
    from cleaned
)


select 
    c.customer_id,
    c.first_name_cleaned as first_name,
    c.last_name_cleaned as last_name,
    c.email_cleaned_no_spaces as email,
    c.phone_number_cleaned as phone_number,
    c.date_of_birth_cleaned as date_of_birth,
    c.cleaned_gender as gender,
    c.cleaned_nationality as nationality,
    c.age as age,
    c.age_bucketed as age_bucket,
    c.tenure_months as tenure,

    -- extract(year from age(current_date, c.date_of_birth_cleaned)) as age,
    -- extract(year from age(current_date, c.registration_date_cleaned::date)) * 12 +
    -- extract(month from age(current_date, c.registration_date_cleaned::date)) as tenure_months,
    geo.geo_id as geo_id,
    c.kyc_status_cleaned as kyc_status,
    c.status_cleaned as status,
    c.risk_score,
    c.registration_date_cleaned as registration_date,
    cs.segment_id as segment_id,
    c.address_cleaned as address,
    case
            when c.relationship_manager_cleaned is null then null
            else rm.relationship_manager_id
        end as relationship_manager_id
    from cleaned_age_bucket_included c
    left join {{ ref('customer_segments') }} cs
        on c.customer_segment_cleaned = cs.segment_name
    left join {{ ref('relationship_managers') }} rm
        on c.relationship_manager_cleaned = rm.relationship_manager
    left join {{ ref('geography')}} geo
        on lower(trim(c.country_cleaned)) = lower(trim(geo.country))
        and lower(trim(c.city_cleaned)) = lower(trim(geo.city))