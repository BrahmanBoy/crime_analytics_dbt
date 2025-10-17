with crimes as (
  select
    crime_sk, occurred_date,
    to_geography(st_makepoint(crime_lon, crime_lat)) as crime_geo
  from {{ ref('fct_crime_events') }}
  where crime_lat is not null and crime_lon is not null
),
stations as (
  select
    station_id, station_name, station_lat, station_lon,
    to_geography(st_makepoint(station_lon, station_lat)) as station_geo
  from {{ ref('dim_transit_stations') }}
),
nearest as (
  -- Assign each crime to its nearest station (meters)
  select
    c.crime_sk,
    s.station_id,
    s.station_name,
    st_distance(c.crime_geo, s.station_geo) as meters_away,
    row_number() over (partition by c.crime_sk order by st_distance(c.crime_geo, s.station_geo)) as rn
  from crimes c
  cross join stations s
)
select
  n.station_id,
  max(n.station_name) as station_name,
  max(s.station_lat) as station_lat,
  max(s.station_lon) as station_lon,
  count(*) as crime_count,
  avg(case when n.rn = 1 then meters_away end) as avg_distance_m
from nearest n
join {{ ref('dim_transit_stations') }} s using (station_id)
where n.rn = 1
group by n.station_id
order by crime_count desc, station_name
