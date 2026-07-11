-- An order can't be delivered before it was purchased. Delivery timing feeds
-- the churn/retention narrative, so a reversed timestamp here would be a
-- silent data-quality issue worth catching before it reaches Power BI.

select order_id, order_purchase_timestamp, order_delivered_customer_date
from {{ ref('stg_olist__orders') }}
where order_delivered_customer_date is not null
  and order_purchase_timestamp is not null
  and order_delivered_customer_date < order_purchase_timestamp
