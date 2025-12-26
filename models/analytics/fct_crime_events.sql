-- Source columns: ADDRESS, CASE_NUMBER, NEIGHBORHOOD, OCCUR_DATE, OFFENSE_TYPE, OPENDATALAT, OPENDATALON
with base as (
  select
    CASE_NUMBER                                        as crime_id,
    try_to_date(OCCUR_DATE)                            as occurred_date,
    OFFENSE_TYPE                                       as offense_type,
    try_to_double(nullif(OPENDATALAT, 'NOT AVAILABLE')) as crime_lat,
    try_to_double(nullif(OPENDATALON, 'NOT AVAILABLE')) as crime_lon,
    ADDRESS,
    NEIGHBORHOOD
  from {{ ref('stg_crime') }}
)
select
  {{ dbt_utils.generate_surrogate_key(['crime_id']) }} as crime_sk,
  crime_id,
  -- Convert DATE -> TIMESTAMP using non-TRY cast (this is valid in Snowflake)
  to_timestamp_ntz(occurred_date)                      as occurred_at,
  occurred_date,
  offense_type,
  crime_lat,
  crime_lon,
  ADDRESS,
  NEIGHBORHOOD
from base
where occurred_date is not null
