-- Raw table has heavy duplication on zip prefix (~1M rows -> ~19K after dedup, see notebooks/eda.ipynb).
with city_ranks as (
    select
        geolocation_zip_code_prefix,
        geolocation_city,
        row_number() over (partition by geolocation_zip_code_prefix order by count(*) desc) as rk
    from {{ source('olist', 'olist_geolocation_dataset') }}
    group by geolocation_zip_code_prefix, geolocation_city
),

state_ranks as (
    select
        geolocation_zip_code_prefix,
        geolocation_state,
        row_number() over (partition by geolocation_zip_code_prefix order by count(*) desc) as rk
    from {{ source('olist', 'olist_geolocation_dataset') }}
    group by geolocation_zip_code_prefix, geolocation_state
)

select
    s.geolocation_zip_code_prefix as zip_code_prefix,
    AVG(s.geolocation_lat) as geolocation_lat,
    AVG(s.geolocation_lng) as geolocation_lng,
    city_ranks.geolocation_city,
    state_ranks.geolocation_state
from {{ source('olist', 'olist_geolocation_dataset') }} s
left join city_ranks on s.geolocation_zip_code_prefix = city_ranks.geolocation_zip_code_prefix and city_ranks.rk = 1
left join state_ranks on s.geolocation_zip_code_prefix = state_ranks.geolocation_zip_code_prefix and state_ranks.rk = 1
group by s.geolocation_zip_code_prefix, city_ranks.geolocation_city, state_ranks.geolocation_state
