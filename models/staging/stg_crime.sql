with src as (
  select * from {{ source('crime_src', 'FILTERED_OFFENSES') }}
)
select
  -- pick/rename only what you need; keep minimal for now
  *
from src
