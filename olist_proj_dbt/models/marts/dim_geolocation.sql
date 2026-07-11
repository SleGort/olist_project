select
    zip_code_prefix,
    geolocation_city,
    geolocation_state,
    geolocation_lat,
    geolocation_lng
from {{ ref('stg_olist__geolocation') }}