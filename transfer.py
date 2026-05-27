import pandas as pd
import psycopg2
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus


pg_conn = psycopg2.connect(
    host="pg-cb6c172-project-0153.j.aivencloud.com",
    port=27284,
    database="defaultdb",
    user="avnadmin",
    password=""
)

sf_password = quote_plus("")

sf_engine = create_engine(
    f"snowflake://Local:{sf_password}"
    "@qj36223.ap-southeast-1/DBT_PRACTICE/RAW"
    "?warehouse=COMPUTE_WH&role=ACCOUNTADMIN"
)

tables = [
    "customers",
    "products",
    "orders"
]

for table in tables:

    print(f"\nLoading table: {table}")

    query = f"SELECT * FROM raw_source.{table}"

    df = pd.read_sql(query, pg_conn)

    print(f"Rows fetched: {len(df)}")

    target_table = f"RAW_{table.upper()}"

    with sf_engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {target_table}"))

    print(f"{target_table} truncated")

    df.to_sql(
        name=target_table,
        con=sf_engine,
        if_exists="append",
        index=False,
        chunksize=1000,
        method="multi"
    )

    print(f"{target_table} loaded successfully!")

pg_conn.close()

print("\nMigration completed successfully!")