-- Source columns available: NAME, INTERSECTION, CITY, STATE, LAT, LON, NOTES
select
  -- Stable synthetic ID for stations
  {{ dbt_utils.generate_surrogate_key(['NAME','INTERSECTION','CITY','STATE']) }} as station_id,
  NAME         as station_name,
  try_to_double(LAT) as station_lat,
  try_to_double(LON) as station_lon,
  CITY,
  STATE,
  INTERSECTION,
  NOTES
from {{ ref('stg_transit_stops') }}

