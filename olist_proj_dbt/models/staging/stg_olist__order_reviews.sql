-- review_comment_title/message dropped: >50% null, not used (no NLP scope). review_id is not
-- unique per row -- same review can appear against multiple orders, see notebooks/eda.ipynb.
select
    review_id,
    order_id,
    review_score,
    cast(review_creation_date as datetime2) as review_creation_date,
    cast(review_answer_timestamp as datetime2) as review_answer_timestamp
from {{ source('olist', 'olist_order_reviews_dataset') }}
