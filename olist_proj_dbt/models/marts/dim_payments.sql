with ranked_type as(
    select
        order_id,
        payment_type,
        row_number() over(partition by order_id order by payment_sequential asc) as type_rank
    from {{ ref('stg_olist__order_payments') }}
),

ranked_installments as(
    select
        order_id,
        payment_installments,
        row_number() over(partition by order_id order by payment_sequential asc) as installments_rank
    from {{ ref('stg_olist__order_payments') }}
),

payment_values as(
    select
        order_id,
        sum(payment_value) as payment_value
    from {{ ref('stg_olist__order_payments') }}
    group by order_id
)

select
    s.order_id,
    rt.payment_type,
    ri.payment_installments,
    pv.payment_value,
    count(s.order_id) as payment_methods_count
from {{ ref('stg_olist__order_payments') }} as s
left join ranked_type as rt
on s.order_id = rt.order_id and rt.type_rank = 1
left join ranked_installments as ri
on s.order_id = ri.order_id and ri.installments_rank = 1
left join payment_values as pv
on s.order_id = pv.order_id
group by s.order_id, rt.payment_type, ri.payment_installments, pv.payment_value