{{ config(materialized='view', tags=['staging','crime']) }}

with src as (
  select
    {{ dbt_utils.generate_surrogate_key(['case_number']) }} as crime_sk,
    cast(case_number as varchar) as incident_id,
    try_to_timestamp_ntz(occur_date) as occurred_at_ts,
    try_to_number(opendatalat)::float as latitude,
    try_to_number(opendatalon)::float as longitude,
    lower(trim(offense_type)) as crime_type_raw,
    initcap(trim(neighborhood)) as neighborhood,
    initcap(trim(address)) as address,
    try_to_timestamp_ntz(occur_date)::date as occurred_on_date
  from {{ source('src_crime','filtered_offenses') }}
),
mapped as (
  select *,
    case
      when crime_type_raw like '%assault%' then 'assault'
      when crime_type_raw like '%burglar%' then 'burglary'
      when crime_type_raw like '%robbery%' then 'robbery'
      when crime_type_raw like '%homicide%' or crime_type_raw like '%murder%' then 'homicide'
      when crime_type_raw like '%theft%' or crime_type_raw like '%larceny%' then 'theft'
      when crime_type_raw like '%fraud%' then 'fraud'
      when crime_type_raw like '%vandal%' or crime_type_raw like '%mischief%' then 'vandalism'
      else 'other'
    end as crime_type_std
  from src
)
select * from mapped;
