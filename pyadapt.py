import pandas as pd
import psycopg2
import yaml
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

#Postgress connection
with open("config.yml", "r") as file:
    config = yaml.safe_load(file)

pg = config["postgres"]

pg_conn = psycopg2.connect(
    host=pg["host"],
    port=pg["port"],
    database=pg["database"],
    user=pg["user"],
    password=pg["password"]
)

print("Connected to Postgres")

#Snowflake connection
sf = config["snowflake"]

sf_password = quote_plus(sf["password"])

sf_engine = create_engine(
    f"snowflake://{sf['user']}:{sf_password}"
    f"@{sf['account']}/{sf['database']}/{sf['schema']}"
    f"?warehouse={sf['warehouse']}&role={sf['role']}"
)

print("Connected to Snowflake")

# -------------------------
# AUTO DISCOVER TABLES
# -------------------------
table_query = """
SELECT table_name
FROM information_schema.tables
WHERE table_schema='raw_source'
AND table_type='BASE TABLE'
"""

tables = pd.read_sql(table_query, pg_conn)

table_names = tables["table_name"].tolist()

print(f"Found {len(table_names)} tables")
print(table_names)

# -------------------------
# LOAD ALL TABLES
# -------------------------
for table in table_names:

    print(f"\nLoading table: {table}")

    query = f"SELECT * FROM raw_source.{table}"

    df = pd.read_sql(query, pg_conn)

    print(f"Rows fetched: {len(df)}")

    # Snowflake likes uppercase
    df.columns = [c.upper() for c in df.columns]

    target_table = f"RAW_{table.upper()}"

    with sf_engine.begin() as conn:

        # Create if not exists
        conn.execute(text(
            f"""
            CREATE TABLE IF NOT EXISTS {target_table}
            AS SELECT * FROM {target_table}
            WHERE 1=0
            """
        ))

        conn.execute(
            text(f"TRUNCATE TABLE {target_table}")
        )

    print(f"{target_table} truncated")

    df.to_sql(
        name=target_table,
        con=sf_engine,
        if_exists="append",
        index=False,
        chunksize=1000,
        method="multi"
    )

    print(f"{target_table} loaded successfully")

# -------------------------
# CLOSE CONNECTIONS
# -------------------------
pg_conn.close()
sf_engine.dispose()

print("\nMigration completed successfully!")