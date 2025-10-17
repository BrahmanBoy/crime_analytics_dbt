with base as (
  select occurred_date
  from {{ ref('fct_crime_events') }}
  where occurred_date is not null
)
select occurred_date, count(*) as crime_count
from base
group by 1
order by 1
