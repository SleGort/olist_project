-- Grain: one row per order item (see notebooks/eda.ipynb, "fact_sales" cell).
-- order_items is already at item grain; only bring order_purchase_timestamp
-- + customer_id onto each line so date/customer dimensions can connect.
-- LEFT JOIN keeps every item row, so grain must not fan out.

-- join stg_olist__order_items to stg_olist__orders (order_id, customer_id, order_purchase_timestamp)
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
--  derive:
--    - order_purchase_date_key: order_purchase_timestamp -> YYYYMMDD integer surrogate key (FK -> dim_date)
--    - total_cost: price + freight_value

--  select final columns only:
--    order_id, seller_id, product_id, customer_id, order_purchase_date_key,
--    price, freight_value, total_cost

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


