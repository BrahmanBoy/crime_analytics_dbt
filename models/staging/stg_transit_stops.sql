{{ config(materialized='view', tags=['staging','transit']) }}

with src as (
  select
    {{ dbt_utils.generate_surrogate_key(['NAME','INTERSECTION','LAT','LON']) }} as stop_sk,
    {{ dbt_utils.generate_surrogate_key(['NAME','INTERSECTION']) }}              as stop_id,
    initcap(trim(NAME))            as stop_name,
    try_to_number(LAT)::float      as latitude,
    try_to_number(LON)::float      as longitude,
    initcap(trim(CITY))            as city,
    upper(trim(STATE))             as state,
    nullif(trim(INTERSECTION),'')  as intersection,
    nullif(trim(NOTES),'')         as notes
  from {{ source('src_crime','transit_stations_portland') }}
)
select * from src;

