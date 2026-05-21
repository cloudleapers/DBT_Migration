import pandas as pd
import psycopg2
from sqlalchemy import create_engine, text

# =====================================================
# POSTGRES CONNECTION
# =====================================================

pg_conn = psycopg2.connect(
    host="pg-2c458362-saidbtproj45.h.aivencloud.com",
    port=10855,
    database="dbt_project",
    user="avnadmin",
    password="AVNS_H7K82C6i4OxVPzPLJ9Z"
)

# =====================================================
# SNOWFLAKE ENGINE
# =====================================================

sf_engine = create_engine(
    "snowflake://saikrishna007:Qwerty123456789@jk54382.ap-southeast-1/DBT_PRACTICE/RAW?warehouse=COMPUTE_WH&role=ACCOUNTADMIN"
)

# =====================================================
# TABLES TO MIGRATE
# =====================================================

tables = [
    "customers",
    "products",
    "orders"
]

# =====================================================
# LOAD TABLES
# =====================================================

for table in tables:

    print(f"\nLoading table: {table}")

    # Read from Postgres
    query = f"SELECT * FROM raw_source.{table}"

    df = pd.read_sql(query, pg_conn)

    print(f"Rows fetched: {len(df)}")

    # Snowflake target table
    target_table = f"RAW_{table.upper()}"

    # =================================================
    # TRUNCATE EXISTING TABLE
    # =================================================

    with sf_engine.connect() as conn:

        conn.execute(
            text(f"TRUNCATE TABLE {target_table}")
        )

        conn.commit()

    print(f"{target_table} truncated")

    # =================================================
    # LOAD DATA INTO SNOWFLAKE
    # =================================================

    df.to_sql(
        name=target_table,
        con=sf_engine,
        if_exists="append",
        index=False,
        method="multi"
    )

    print(f"{target_table} loaded successfully!")

# =====================================================
# CLOSE CONNECTIONS
# =====================================================

pg_conn.close()

print("\nMigration completed successfully!")