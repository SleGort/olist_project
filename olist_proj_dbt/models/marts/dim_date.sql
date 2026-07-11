-- Contiguous calendar spine spanning the order purchase dates (see
-- notebooks/eda.ipynb, "dim_date" cell). 
with bounds as (
    select
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date
    from {{ ref('int_order_date_bounds') }}
),

date_range as (
    select
        datediff(day, start_date, end_date) + 1 as days
    from bounds
),
-- Generating a sequence of days to add to the start_date
-- e.g 1, 2, 3, ..., n where n = datediff(day, start_date, end_date)
tally as (
    select top (select days from date_range) row_number() over (order by (select null)) - 1 as n
    from sys.all_columns
),

-- Generating the contiguous calendar spine by adding the sequence of days to the start_date
date_spine as (
    select dateadd(day, t.n, b.start_date) as full_date
    from tally as t
    cross join bounds as b
    where dateadd(day, t.n, b.start_date) <= b.end_date
),

-- Adding additional date attributes to the calendar spine
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

-- Final selection of the date attributes, including a month_index for ordering
select
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    (year - min(year) over ()) * 12 + month - 9 as month_index
from dated
