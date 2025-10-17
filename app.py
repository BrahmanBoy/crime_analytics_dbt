# app.py — Streamlit in Snowflake (no pydeck)

import pandas as pd
import plotly.express as px
import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Transit Crime Dashboard", layout="wide")
st.title("🚉 Transit Crime Trends & Station Risk (Portland)")

session = get_active_session()

@st.cache_data(ttl=600)
def load_df(sql: str) -> pd.DataFrame:
    df = session.sql(sql).to_pandas()
    df.columns = [c.upper() for c in df.columns]
    return df

def coerce_latlon(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df
    df = df.copy()
    # Standardize to LAT/LON
    if "STATION_LAT" in df.columns: df.rename(columns={"STATION_LAT": "LAT"}, inplace=True)
    if "STATION_LON" in df.columns: df.rename(columns={"STATION_LON": "LON"}, inplace=True)
    if "LAT" in df.columns and "LON" in df.columns:
        df["LAT"] = pd.to_numeric(df["LAT"], errors="coerce")
        df["LON"] = pd.to_numeric(df["LON"], errors="coerce")
        df = df.dropna(subset=["LAT", "LON"])
        df = df[df["LAT"].between(-90, 90) & df["LON"].between(-180, 180)]
    return df

# --- Data pulls ---
df_daily = load_df("""
    select occurred_date, crime_count
    from ANALYTICS.FCT_CRIME_BY_DAY
    order by occurred_date
""")

df_station = load_df("""
    select
      station_id,
      station_name,
      station_lat as LAT,
      station_lon as LON,
      crime_count
    from ANALYTICS.FCT_CRIME_BY_STATION__CLOSEST
    order by crime_count desc, station_name
""")
df_station = coerce_latlon(df_station)

# --- UI ---
left, right = st.columns([2, 3], gap="large")

with left:
    st.subheader("Daily Crime Trend")
    if df_daily.empty:
        st.info("No daily data to display.")
    else:
        st.line_chart(df_daily.set_index("OCCURRED_DATE")["CRIME_COUNT"])

    st.subheader("Top Stations by Crime Count")
    top_n = st.slider("Show top N", 5, 50, 15, 5)
    st.dataframe(df_station.head(top_n), use_container_width=True)

with right:
    st.subheader("Station Risk — Geographic View")
    if df_station.empty:
        st.info("No station data to map.")
    else:
        fig = px.scatter_geo(
            df_station,
            lat="LAT",
            lon="LON",
            hover_name="STATION_NAME",
            size="CRIME_COUNT",
            size_max=22,
            opacity=0.85,
        )
        fig.update_geos(fitbounds="locations", scope="north america", showcountries=False, showcoastlines=True)
        st.plotly_chart(fig, use_container_width=True)

st.caption("Data: dbt models in CRIME_DB.ANALYTICS • Runs in Snowflake Streamlit")
