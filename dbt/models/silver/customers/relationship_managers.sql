{{ config(materialized='table') }}

with cleaned as (
    select
        relationship_manager,
        case 
            when lower(trim(relationship_manager)) in ('null', 'na', 'n/a', 'none', '') then null
            else trim(relationship_manager)
        end as relationship_manager_cleaned
    from {{ source('silver', 'stg_customers') }}
)

select distinct
    {{dbt_utils.generate_surrogate_key(['c.relationship_manager'])}} as relationship_manager_id,
    c.relationship_manager_cleaned as relationship_manager
from cleaned c
where relationship_manager_cleaned is not null
