{{config(materialized='table')}}

select 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.gender,
    c.age,
    c.age_bucket,
    geo.country,
    geo.city,
    cs.segment_name as customer_segment,
    c.kyc_status,
    c.status,

    rm.relationship_manager,
    c.registration_date,
    c.risk_score
    from {{ ref('customers') }} c
    left join {{ ref('geography')}} geo
        on c.geo_id = geo.geo_id
    left join {{ ref('customer_segments') }} cs
        on c.segment_id = cs.segment_id
    left join {{ ref('relationship_managers') }} rm
        on c.relationship_manager_id = rm.relationship_manager_id


