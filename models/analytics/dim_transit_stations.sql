select
  {{ dbt_utils.generate_surrogate_key(['station_id', 'station_name']) }} as station_sk,
  station_id,
  station_name,
  latitude as station_lat,
  longitude as station_lon
from {{ ref('stg_transit_stops') }}
