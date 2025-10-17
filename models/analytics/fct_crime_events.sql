-- Keep this thin: one row per crime event, standard columns
select
  {{ dbt_utils.generate_surrogate_key(['crime_id']) }} as crime_sk,
  crime_id,
  try_to_timestamp_ntz(occurred_at) as occurred_at,
  to_date(occurred_at) as occurred_date,
  offense_type,
  severity,                   -- if available
  latitude as crime_lat,      -- if available
  longitude as crime_lon,     -- if available
  station_id                  -- if present in the raw data
from {{ ref('stg_crime') }}
