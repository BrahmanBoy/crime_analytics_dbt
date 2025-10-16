select 
    current_user()     as dbt_user,
    current_role()     as dbt_role,
    current_database() as current_db,
    current_schema()   as current_schema,
    current_warehouse() as dbt_warehouse;
