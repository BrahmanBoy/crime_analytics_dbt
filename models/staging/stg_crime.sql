{{ config(materialized='view', tags=['staging','crime']) }}

with base as (
  select
    cast(CASE_NUMBER as varchar)           as incident_id,
    try_to_timestamp_ntz(OCCUR_DATE)       as occurred_at_ts,
    try_to_number(OPENDATALAT)::float      as latitude,
    try_to_number(OPENDATALON)::float      as longitude,
    lower(trim(OFFENSE_TYPE))              as crime_type_raw,
    initcap(trim(NEIGHBORHOOD))            as neighborhood,
    initcap(trim(ADDRESS))                 as address
  from {{ source('src_crime','filtered_offenses') }}
),

mapped as (
  select
    -- more discriminating key: incident + occurred_at_ts + address + crime_type
    {{ dbt_utils.generate_surrogate_key(
         ['incident_id','cast(occurred_at_ts as varchar)', 'address', 'crime_type_raw']
       ) }}                                as crime_sk,
    incident_id,
    occurred_at_ts,
    latitude,
    longitude,
    case
      when crime_type_raw like '%assault%' then 'assault'
      when crime_type_raw like '%burglar%' then 'burglary'
      when crime_type_raw like '%robbery%' then 'robbery'
      when crime_type_raw like '%homicide%' or crime_type_raw like '%murder%' then 'homicide'
      when crime_type_raw like '%theft%' or crime_type_raw like '%larceny%' then 'theft'
      when crime_type_raw like '%fraud%' then 'fraud'
      when crime_type_raw like '%vandal%' or crime_type_raw like '%mischief%' then 'vandalism'
      else 'other'
    end                                       as crime_type_std,
    neighborhood,
    address
  from base
),

-- In case upstream duplicates still exist on that composite key, keep the first
deduped as (
  select *
  from (
    select
      *,
      row_number() over (
        partition by crime_sk
        order by occurred_at_ts nulls last, incident_id
      ) as _rn
    from mapped
  )
  where _rn = 1
)

select
  crime_sk, incident_id, occurred_at_ts, latitude, longitude,
  crime_type_std, neighborhood, address
from deduped;
