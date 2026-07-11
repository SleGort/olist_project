-- Min/max order_purchase_timestamp date, feeding dim_date's calendar spine
-- (see notebooks/eda.ipynb, cell building `_bounds` from orders_cleaned).

select 
    min(order_purchase_timestamp) as start_date,
    max(order_purchase_timestamp) as end_date
from {{ ref('stg_olist__orders') }}