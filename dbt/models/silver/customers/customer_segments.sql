{{ config(materialized='table') }}

with clean_customer_segment as (
    select distinct  
        case
            when lower(trim(customer_segment)) = 'banca_privada' then 'private_banking'
            when lower(trim(customer_segment)) = 'minorista' then 'retail'
            when lower(trim(customer_segment)) = 'pyme' then 'sme'
            else lower(trim(customer_segment))
        end as customer_segment_cleaned
    from {{ source('silver', 'stg_customers') }}
    where customer_segment is not null 
)

select 
    {{ dbt_utils.generate_surrogate_key(['customer_segment_cleaned']) }} as segment_id,
    customer_segment_cleaned as segment_name 
from clean_customer_segment
order by segment_name  