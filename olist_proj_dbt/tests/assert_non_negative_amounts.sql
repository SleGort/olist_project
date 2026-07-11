-- All monetary amounts feeding revenue/risk calculations must be non-negative.
-- A negative value here would silently corrupt fact_seller_month.revenue and
-- dim_seller.revenue_risk_score downstream.

select order_id, seller_id, product_id, price, freight_value, total_cost, 'fact_sales' as source_table
from {{ ref('fact_sales') }}
where price < 0 or freight_value < 0 or total_cost < 0

union all

select order_id, null as seller_id, null as product_id, payment_value, null as freight_value, null as total_cost, 'dim_payments' as source_table
from {{ ref('dim_payments') }}
where payment_value < 0

union all

select null as order_id, seller_id, null as product_id, revenue, null as freight_value, null as total_cost, 'fact_seller_month' as source_table
from {{ ref('fact_seller_month') }}
where revenue < 0
