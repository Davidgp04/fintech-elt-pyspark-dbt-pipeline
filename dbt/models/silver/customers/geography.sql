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

cleaned as(
    select
    c.country,
    initcap(coalesce(bm.matched_city, lower(trim(c.city)))) as city_cleaned,
    c.lat,
    c.lon




    from {{ source('silver', 'stg_customers') }} c
    left join best_matches bm
        on c.country = bm.country
        and lower(trim(c.city)) = bm.raw_city
),
geo_medians as (
    select
        country,
        city_cleaned,
        percentile_cont(0.5) within group (order by lat) as lat_median,
        percentile_cont(0.5) within group (order by lon) as lon_median
    from cleaned
    where abs(lat) <= 90 and abs(lon) <= 180
     and lat is not null and lon is not null
    group by country, city_cleaned
)

select distinct
    {{dbt_utils.generate_surrogate_key(['c.country','c.city_cleaned'])}} as geo_id,
    trim(c.country) as country,
    c.city_cleaned as city,
    gm.lat_median as lat,
    gm.lon_median as lon
from cleaned c
left join geo_medians gm
    on c.country = gm.country
    and c.city_cleaned = gm.city_cleaned