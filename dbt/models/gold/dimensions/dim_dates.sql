{{
    config(
        materialized='table'
    )
}}

with date_spine as (
    -- Generate dates using PostgreSQL generate_series
    select 
        generate_series(
            '2018-01-01'::date,
            '2030-12-31'::date,
            '1 day'::interval
        )::date as date_day
),

dim_date_calculations as (
    select
        date_day,
        date_trunc('year', date_day)::date as year_start_date,
        extract(year from date_day) as date_year,
        extract(month from date_day) as date_month,
        extract(day from date_day) as date_day_of_month,
        extract(dow from date_day) as date_day_of_week,  -- 0=Sunday, 1=Monday, etc.
        extract(quarter from date_day) as date_quarter,
        -- Generate surrogate key using MD5 or just use date_day as key
        md5(date_day::text) as date_sk
    from date_spine
)

select * from dim_date_calculations