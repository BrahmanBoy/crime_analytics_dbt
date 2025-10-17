with crimes as (
  select station_id
  from {{ ref('fct_crime_events') }}
  where station_id is not null
),
stations as (
  select station_id, station_name, station_lat, station_lon
  from {{ ref('dim_transit_stations') }}
)
select
  s.station_id,
  s.station_name,
  s.station_lat,
  s.station_lon,
  count(c.station_id) as crime_count
from stations s
left join crimes c
  on s.station_id = c.station_id
group by 1,2,3,4
order by crime_count desc, station_name
