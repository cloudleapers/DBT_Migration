import pandas as pd
import psycopg2
import snowflake.connector
from sqlalchemy import create_engine

# -----------------------------
# POSTGRES CONNECTION
# -----------------------------

pg_conn = psycopg2.connect(
    host="pg-2c458362-saidbtproj45.h.aivencloud.com",
    port=10855,
    database="dbt_project",
    user="avnadmin",
    password="AVNS_H7K82C6i4OxVPzPLJ9Z"
)

# -----------------------------
# SNOWFLAKE CONNECTION
# -----------------------------

sf_conn = snowflake.connector.connect(
    user='saikrishna007',
    password='Qwerty123456789',
    account='jk54382.ap-southeast-1',
    warehouse='COMPUTE_WH',
    database='DBT_PRACTICE',
    schema='RAW',
    role='ACCOUNTADMIN'
)

tables = ['customers', 'products', 'orders']

for table in tables:

    print(f"Loading {table}...")

    query = f"select * from raw_source.{table}"

    df = pd.read_sql(query, pg_conn)

    engine = create_engine(
        'snowflake://saikrishna007:Qwerty123456789@jk54382.ap-southeast-1/DBT_PRACTICE/RAW?warehouse=COMPUTE_WH&role=ACCOUNTADMIN'
    )

    df.to_sql(
        name=f'RAW_{table.upper()}',
        con=engine,
        if_exists='replace',
        index=False
    )

    print(f"{table} loaded successfully")

print("Migration completed")