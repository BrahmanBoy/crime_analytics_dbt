import os
import pandas as pd
import streamlit as st
import snowflake.connector
import pydeck as pdk

st.set_page_config(page_title="Transit Crime Dashboard", layout="wide")

# --- Connect to Snowflake ---
def sf_conn():
    return snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),  # e.g. abcd-xy12345
        warehouse="COMPUTE_WH",
        database="CRIME_DB",
        schema="ANALYTICS",
        role=os.getenv("SNOWFLAKE_ROLE", None)
    )

@st.cache_data(ttl=600)
def load_df(query):
    with sf_conn() as con:
        return pd.read_sql(query, con)

# --- Load data from dbt models ---
df_daily = load_df("""
    select occurred_date, crime_count
    from ANALYTICS.FCT_CRIME_BY_DAY
    order by occurred_date
""")

df_station = load_df("""
    select station_id, station_name, station_lat as lat, station_lon as lon, crime_count
    from ANALYTICS.FCT_CRIME_BY_STATION__CLOSEST
    order by crime_count desc, station_name
""")

# --- UI ---
st.title("🚉 Transit Crime Trends & Station Risk (Portland)")

col1, col2 = st.columns([2, 3])

with col1:
    st.subheader("Daily Crime Trend")
    st.line_chart(df_daily.set_index("occurred_date")["crime_count"])

    st.subheader("Top Stations by Crime Count")
    top_n = st.slider("Show top N", min_value=5, max_value=50, value=15, step=5)
    st.dataframe(df_station.head(top_n))

with col2:
    st.subheader("Station Risk Map")
    if not df_station.empty:
        view_state = pdk.ViewState(
            latitude=float(df_station["lat"].mean()),
            longitude=float(df_station["lon"].mean()),
            zoom=10.5,
            pitch=0
        )
        layer = pdk.Layer(
            "ScatterplotLayer",
            data=df_station,
            get_position='[lon, lat]',
            get_radius="max(crime_count, 1) * 20",
            get_color=[255, 0, 0, 180],
            pickable=True
        )
        st.pydeck_chart(
            pdk.Deck(
                layers=[layer],
                initial_view_state=view_state,
                tooltip={"text": "{station_name}\nCrimes: {crime_count}"}
            )
        )
    else:
        st.info("No station data available.")

st.caption("Data source: CRIME_DB.ANALYTICS (dbt models).")
