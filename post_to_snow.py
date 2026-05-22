import pandas as pd
import psycopg2
from sqlalchemy import create_engine, text

pg_conn = psycopg2.connect(
    host="pg-313c56b-tharnikareddy01-pa06.j.aivencloud.com",
    port=18679,
    database="defaultdb",
    user="avnadmin",
    password="REDACTED"
)

sf_engine = create_engine(
    "snowflake://PTHARNIKA:Tharnika%40010604@BI36122.ap-southeast-1/DBT_PRACTICE/RAW?warehouse=COMPUTE_WH&role=ACCOUNTADMIN"
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

   

    with sf_engine.connect() as conn:

        conn.execute(
            text(f"TRUNCATE TABLE {target_table}")
        )

        conn.commit()

    print(f"{target_table} truncated")

   

    df.to_sql(
        name=target_table,
        con=sf_engine,
        if_exists="append",
        index=False,
        method="multi"
    )

    print(f"{target_table} loaded successfully!")



pg_conn.close()

print("\nMigration completed successfully!")