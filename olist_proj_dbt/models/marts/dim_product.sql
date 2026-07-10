with translation as (
    select  * 
    from {{ ref('stg_olist__category_translation') }}
)

select 
    p.product_id,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    t.product_category_name_english
from {{ ref('stg_olist__products') }} as p
left join translation as t
on p.product_category_name = t.product_category_name