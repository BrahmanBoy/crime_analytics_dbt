with src as (
  select * from {{ source('crime_src', 'TRANSIT_STATIONS_PORTLAND') }}
)
select
  *
from src
