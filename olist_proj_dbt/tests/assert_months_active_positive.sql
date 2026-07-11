-- months_active is a count(distinct month_index) with a >= 1 floor implied by
-- its definition -- a seller row appearing in dim_seller via the left join to
-- fact_seller_month should never resolve to 0 or a negative count.

select seller_id, months_active
from {{ ref('dim_seller') }}
where months_active is not null
  and months_active < 1
