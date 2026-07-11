select
    customer_id,
    customer_city,
    customer_state,
    customer_zip_code_prefix
from {{ ref('stg_olist__customers') }}