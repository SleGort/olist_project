-- Contiguous calendar spine spanning the order purchase dates (see
-- notebooks/eda.ipynb, "dim_date" cell). Not just the dates that appear --
-- every day in [min(order_purchase_timestamp), max(order_purchase_timestamp)]
-- so Power BI can mark it as a Date Table with a clean hierarchy.

with bounds as (
    select
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date
    from {{ ref('int_order_date_bounds') }}
),

-- Number of days to generate: enough to cover the widest possible order
-- date range without relying on a recursive CTE (which needs MAXRECURSION
-- set on the outer statement -- not available once dbt wraps this query
-- in CREATE TABLE AS). 4 cross-joined 10-value CTEs give up to 10,000 rows.
digits as (
    select column1 as digit
    from (values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) as d(column1)
),

tally as (
    select row_number() over (order by (select null)) - 1 as n
    from digits as d1
    cross join digits as d2
    cross join digits as d3
    cross join digits as d4
),

date_spine as (
    select dateadd(day, t.n, b.start_date) as full_date
    from tally as t
    cross join bounds as b
    where dateadd(day, t.n, b.start_date) <= b.end_date
),

dated as (
    select
        full_date,
        cast(convert(varchar(8), full_date, 112) as integer) as date_key,
        year(full_date) as year,
        datepart(quarter, full_date) as quarter,
        month(full_date) as month,
        datename(month, full_date) as month_name
    from date_spine
)

select
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    (year - min(year) over ()) * 12 + month - 9 as month_index
from dated
