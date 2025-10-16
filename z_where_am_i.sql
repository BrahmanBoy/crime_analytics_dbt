{{ config(materialized='table') }}

select
  current_account()      as account,
  current_region()       as region,
  current_user()         as user_name,
  current_role()         as role_name,
  current_database()     as db_name,
  current_schema()       as schema_name,
  current_warehouse()    as wh_name,
  '{{ invocation_id }}'  as dbt_invocation_id
