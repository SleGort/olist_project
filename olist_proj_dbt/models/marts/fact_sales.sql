with cleaned_orders as (
    select
        order_id,
        customer_id,
        order_purchase_timestamp
    from {{ ref('stg_olist__orders') }} 
),

cleaned_order_items as (
    select
        order_id,
        product_id,
        seller_id,
        price,
        freight_value
    from {{ ref('stg_olist__order_items') }} 
),

joined as (
    select o.order_id,
           o.customer_id,
           o.order_purchase_timestamp,
           oi.product_id,
           oi.seller_id,
           oi.price,
           oi.freight_value
    from cleaned_order_items as oi
    left join cleaned_orders as o
    on oi.order_id = o.order_id
)

select
    j.order_id,
    j.seller_id,
    j.product_id,
    j.customer_id,
    j.price,
    j.freight_value,
    cast(convert(varchar(8), j.order_purchase_timestamp, 112) as integer) as order_purchase_date_key,
    (j.price + j.freight_value) as total_cost
from joined as j
