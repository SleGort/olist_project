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
