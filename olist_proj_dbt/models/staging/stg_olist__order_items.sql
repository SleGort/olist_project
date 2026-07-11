select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    cast(shipping_limit_date as datetime2) as shipping_limit_date,
    price,
    freight_value
from {{ source('olist', 'olist_order_items_dataset') }}
