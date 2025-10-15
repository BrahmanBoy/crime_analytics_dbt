{{ config(materialized='view', tags=['staging','transit']) }}

with src as (
  select
    {{ dbt_utils.generate_surrogate_key(['name','intersection','lat','lon']) }} as stop_sk,
    {{ dbt_utils.generate_surrogate_key(['name','intersection']) }} as stop_id,
    initcap(trim(name)) as stop_name,
    try_to_numeric(lat) as latitude,
    try_to_numeric(lon) as longitude,
    initcap(trim(city)) as city,
    upper(trim(state)) as state,
    nullif(trim(intersection),'') as intersection,
    nullif(trim(notes),'') as notes
  from {{ source('src_crime','transit_stations_portland') }}
)
select * from src;
