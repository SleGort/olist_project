-- customer_unique_id is not actually unique across rows, so it's dropped (see notebooks/eda.ipynb)
select
    customer_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from {{ source('olist', 'olist_customers_dataset') }}
