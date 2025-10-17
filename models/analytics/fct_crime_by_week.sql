with base as (
  select date_trunc(week, occurred_date) as week_start
  from {{ ref('fct_crime_events') }}
  where occurred_date is not null
)
select
  week_start,
  count(*) as crime_count
from base
group by 1
order by 1
