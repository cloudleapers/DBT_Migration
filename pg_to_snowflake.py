# pg_to_snowflake.py
import os
import yaml
import pandas as pd
from sqlalchemy import create_engine
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas

# Step 1: Read profiles.yml 
profiles_path = os.path.join(os.path.dirname(__file__), "~\\.dbt", "profiles.yml")

with open(profiles_path, "r") as f:
    profiles = yaml.safe_load(f)

pg_config = profiles["my_project"]["outputs"]["postgres"]
sf_config = profiles["my_project"]["outputs"]["snowflake"]

print("Loaded credentials from profiles.yml")


# Step 2: Connect to Postgres using SQLAlchemy
# SQLAlchemy is just a bridge — pandas needs it to read SQL properly
pg_engine = create_engine(
    f"postgresql+psycopg2://{pg_config['user']}:{pg_config['password']}"
    f"@{pg_config['host']}:{pg_config['port']}/{pg_config['dbname']}",
    connect_args={
        "sslmode":    pg_config["sslmode"],
        "sslrootcert": pg_config["sslrootcert"],
    }
)
print("Connected to Postgres (Aiven)")


# Step 3: Connect to Snowflake 
sf_conn = snowflake.connector.connect(
    account   = sf_config["account"],
    user      = sf_config["user"],
    password  = sf_config["password"],
    warehouse = sf_config["warehouse"],
    database  = sf_config["database"],
    role      = sf_config["role"],
    schema    = "RAW",
)
print("Connected to Snowflake")


#Step 4: Auto-discover tables in Postgres
with pg_engine.connect() as conn:
    result = conn.execute(
        __import__("sqlalchemy").text("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'raw_source'
              AND table_type = 'BASE TABLE'
        """)
    )
    tables = [row[0] for row in result]

print(f"Found {len(tables)} tables: {tables}")


# Step 5: Copy each table into Snowflake RAW schema 
for table in tables:

    print(f"\n Copying: {table} ...")

    # Read from Postgres (SQLAlchemy engine works perfectly with pandas)
    df = pd.read_sql(f"SELECT * FROM raw_source.{table}", pg_engine)

    # Snowflake needs UPPERCASE column names
    df.columns = [col.upper() for col in df.columns]

    # e.g. customers → RAW_CUSTOMERS
    sf_table = f"RAW_{table.upper()}"

    # Write to Snowflake
    success, _, num_rows, _ = write_pandas(
        conn              = sf_conn,
        df                = df,
        table_name        = sf_table,
        auto_create_table = True,
        overwrite         = True,
    )

    if success:
        print(f" {sf_table} = {num_rows} rows loaded")
    else:
        print(f" {sf_table}  something went wrong")


# Step 6: Close connections 
pg_engine.dispose()
sf_conn.close()
print("\n Done! Check Snowflake -> DBT_PRACTICE -> RAW schema")