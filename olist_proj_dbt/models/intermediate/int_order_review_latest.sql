-- One row per order_id: latest review score, since review_reviews is not unique per order
-- (see notebooks/eda.ipynb, cell "order_review" under dim_order construction).
select
    order_id,
    review_score
from (
    select
        order_id,
        review_score,
        row_number() over (
            partition by order_id
            order by review_creation_date desc
        ) as rn
    from {{ ref('stg_olist__order_reviews') }}
) ranked
where rn = 1
