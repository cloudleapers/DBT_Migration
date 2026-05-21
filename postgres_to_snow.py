import pandas as pd
import psycopg2
from sqlalchemy import create_engine, text
# PostgreSQL Connection
postgres_conn = psycopg2.connect(
    host="pg-3d453efa-koppalaguruprasad-dbt20.h.aivencloud.com",
    port=10560,
    database="defaultdb",
    user="avnadmin",
    password="REDACTED"
)
# Snowflake Connection
snowflake_engine = create_engine(
    "snowflake://Guru:Guruprasad%403519@zj71425.ap-southeast-1/DBT_PRACTICE/RAW?warehouse=COMPUTE_WH&role=ACCOUNTADMIN"
)
def load_table(source_table, target_table):
    # Read data from PostgreSQL
    sql_query = f"SELECT * FROM raw_source.{source_table}"
    data = pd.read_sql(sql_query, postgres_conn)
    print(data.head())
    
    # Remove old data from Snowflake
    with snowflake_engine.connect() as conn:
        conn.execute(
            text(f"TRUNCATE TABLE RAW.{target_table}")
        )
        conn.commit()
    # Load latest data
    data.to_sql(
        name=target_table,
        con=snowflake_engine,
        schema="RAW",
        if_exists="append",
        index=False
    )
    print(f"{target_table} loaded successfully")
    
# Load all tables
load_table("customers", "RAW_CUSTOMERS")
load_table("products", "RAW_PRODUCTS")
load_table("orders", "RAW_ORDERS")

# Close connection
postgres_conn.close()
print("\nMigration Completed Successfully")
