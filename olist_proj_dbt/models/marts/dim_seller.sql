-- dim_seller: base seller attributes + two enrichments from fact_seller_month
-- (see notebooks/eda.ipynb, "dim_seller enrichment" cells).
with months_active as (
    select
        seller_id,
        count(distinct month_index) as months_active
    from {{ ref('fact_seller_month') }}
    group by seller_id
),

-- OLS slope of revenue over month_index
risk_inputs as (
    select
        seller_id,
        count(*) as n,
        sum(month_index) as sx,
        sum(revenue) as sy,
        sum(month_index * revenue) as sxy,
        sum(cast(month_index as float) * month_index) as sxx,
        avg(revenue) as mean_rev
    from {{ ref('fact_seller_month') }}
    where month_index between 4 and 23
    group by seller_id
),

revenue_risk as (
    select
        seller_id,
        case
            when n >= 12 and mean_rev > 0
                then ((n * sxy - sx * sy) / (n * sxx - cast(sx as float) * sx)) / mean_rev
            else null
        end as revenue_risk_score
    from risk_inputs
)

select
    s.seller_id,
    s.seller_city,
    s.seller_state,
    s.seller_zip_code_prefix,
    ma.months_active,
    rr.revenue_risk_score
from {{ ref('stg_olist__sellers') }} as s
left join months_active as ma
    on s.seller_id = ma.seller_id
left join revenue_risk as rr
    on s.seller_id = rr.seller_id
