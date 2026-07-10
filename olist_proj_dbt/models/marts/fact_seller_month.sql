with dim_date as (
    select 
        date_key,
        month_index
    from {{ ref('dim_date') }}
)

select fs.seller_id, dd.month_index, sum(total_cost) as revenue
from {{ ref('fact_sales') }} fs
left join dim_date dd
    on fs.order_purchase_date_key = dd.date_key
group by fs.seller_id, dd.month_index