{{ config(materialized='view', tags=['staging','transit']) }}

with base as (
  select
    initcap(trim(NAME))            as stop_name,
    nullif(trim(INTERSECTION),'')  as intersection,
    try_to_number(LAT)::float      as latitude,
    try_to_number(LON)::float      as longitude,
    initcap(trim(CITY))            as city,
    upper(trim(STATE))             as state,
    nullif(trim(NOTES),'')         as notes
  from {{ source('src_crime','transit_stations_portland') }}
),

keyed as (
  select
    {{ dbt_utils.generate_surrogate_key(['stop_name','intersection','cast(latitude as varchar)','cast(longitude as varchar)']) }} as stop_sk,
    {{ dbt_utils.generate_surrogate_key(['stop_name','intersection']) }} as stop_id,
    stop_name, latitude, longitude, city, state, intersection, notes
  from base
),

deduped as (
  select *
  from (
    select
      *,
      row_number() over (
        partition by stop_sk
        order by stop_name
      ) as _rn
    from keyed
  )
  where _rn = 1
)

select stop_sk, stop_id, stop_name, latitude, longitude, city, state, intersection, notes
from deduped;
