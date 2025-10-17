-- Source columns: ADDRESS, CASE_NUMBER, NEIGHBORHOOD, OCCUR_DATE, OFFENSE_TYPE, OPENDATALAT, OPENDATALON
select
  {{ dbt_utils.generate_surrogate_key(['CASE_NUMBER']) }}              as crime_sk,
  CASE_NUMBER                                                          as crime_id,
  try_to_timestamp_ntz(try_to_date(OCCUR_DATE))                        as occurred_at,
  try_to_date(OCCUR_DATE)                                              as occurred_date,
  OFFENSE_TYPE                                                         as offense_type,
  try_to_double(nullif(OPENDATALAT, 'NOT AVAILABLE'))                  as crime_lat,
  try_to_double(nullif(OPENDATALON, 'NOT AVAILABLE'))                  as crime_lon,
  ADDRESS,
  NEIGHBORHOOD
from {{ ref('stg_crime') }}

