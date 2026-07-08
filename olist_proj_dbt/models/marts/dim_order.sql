-- Worked example establishing the marts pattern. Remaining gold-layer tables
-- (fact_sales, fact_seller_month, dim_seller, dim_product, dim_customer,
-- dim_payments, dim_date, dim_geolocation) still need to be built to replicate
-- notebooks/eda.ipynb's Silver -> Gold section (cell "Silver to Gold - Reshaping
-- the data for business analysis").
select
    o.order_id,
    o.order_status,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    r.review_score
from {{ ref('stg_olist__orders') }} o
left join {{ ref('int_order_review_latest') }} r
    on o.order_id = r.order_id
