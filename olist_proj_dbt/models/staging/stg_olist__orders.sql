select
    order_id,
    customer_id,
    order_status,
    cast(order_purchase_timestamp as datetime2) as order_purchase_timestamp,
    cast(order_approved_at as datetime2) as order_approved_at,
    cast(order_delivered_carrier_date as datetime2) as order_delivered_carrier_date,
    cast(order_delivered_customer_date as datetime2) as order_delivered_customer_date,
    cast(order_estimated_delivery_date as datetime2) as order_estimated_delivery_date
from {{ source('olist', 'olist_orders_dataset') }}
