-- Raw table has heavy duplication on zip prefix (~1M rows -> ~19K after dedup, see notebooks/eda.ipynb).
-- city/state picked from the most frequent (city, state) pair per prefix, matching polars .mode().first().
with city_state_counts as (
    select
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        count(*) as pair_count,
        row_number() over (
            partition by geolocation_zip_code_prefix
            order by count(*) desc
        ) as rn
    from {{ source('olist', 'olist_geolocation_dataset') }}
    group by geolocation_zip_code_prefix, geolocation_city, geolocation_state
)

select
    g.geolocation_zip_code_prefix as zip_code_prefix,
    avg(g.geolocation_lat) as geolocation_lat,
    avg(g.geolocation_lng) as geolocation_lng,
    max(cs.geolocation_city) as geolocation_city,
    max(cs.geolocation_state) as geolocation_state
from {{ source('olist', 'olist_geolocation_dataset') }} g
inner join city_state_counts cs
    on g.geolocation_zip_code_prefix = cs.geolocation_zip_code_prefix
    and cs.rn = 1
group by g.geolocation_zip_code_prefix
