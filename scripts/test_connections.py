"""
Test each database connection independently.
"""
import os
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text
from snowflake.sqlalchemy import URL as snowflake_url
from dotenv import load_dotenv

load_dotenv()

print("=" * 60)
print("CONNECTION DIAGNOSTIC")
print("=" * 60)

# ---- POSTGRES TEST ----
print("\n[1/3] Testing PostgreSQL (Supabase)...")
try:
    pg_pwd = quote_plus(os.getenv('PG_PASSWORD'))
    pg_user = quote_plus(os.getenv('PG_USER'))
    pg_url = (f"postgresql+psycopg2://{pg_user}:{pg_pwd}"
              f"@{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}"
              f"?sslmode=require")
    pg_engine = create_engine(pg_url)
    with pg_engine.connect() as conn:
        count = conn.execute(text("SELECT COUNT(*) FROM patients")).scalar()
        print(f"  PostgreSQL connected. patients table has {count} rows")

        result = conn.execute(text("""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """))
        tables = [r[0] for r in result]
        print(f"  Found {len(tables)} tables: {tables[:5]}...")
except Exception as e:
    print(f"  PostgreSQL FAILED: {e}")

# ---- MYSQL TEST ----
print("\n[2/3] Testing MySQL (Aiven)...")
try:
    mysql_pwd = quote_plus(os.getenv('MYSQL_PASSWORD'))
    mysql_user = quote_plus(os.getenv('MYSQL_USER'))
    mysql_url = (f"mysql+pymysql://{mysql_user}:{mysql_pwd}"
                 f"@{os.getenv('MYSQL_HOST')}:{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DATABASE')}")
    mysql_engine = create_engine(mysql_url, connect_args={'ssl': {'ssl_disabled': False}})
    with mysql_engine.connect() as conn:
        count = conn.execute(text("SELECT COUNT(*) FROM claims")).scalar()
        print(f"  MySQL connected. claims table has {count} rows")

        result = conn.execute(text("""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """))
        tables = [r[0] for r in result]
        print(f"  Found {len(tables)} tables: {tables[:5]}...")
except Exception as e:
    print(f"  MySQL FAILED: {e}")

# ---- SNOWFLAKE TEST ----
print("\n[3/3] Testing Snowflake...")
try:
    sf_engine = create_engine(snowflake_url(
        account=os.getenv('SF_ACCOUNT'),
        user=os.getenv('SF_USER'),
        password=os.getenv('SF_PASSWORD'),
        role=os.getenv('SF_ROLE'),
        database=os.getenv('SF_DATABASE'),
        warehouse=os.getenv('SF_WAREHOUSE'),
        schema=os.getenv('SF_RAW_SCHEMA'),
    ))
    with sf_engine.connect() as conn:
        result = conn.execute(text("SELECT CURRENT_USER(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE()"))
        row = result.fetchone()
        print(f"  Snowflake connected.")
        print(f"    User      = {row[0]}")
        print(f"    Database  = {row[1]}")
        print(f"    Schema    = {row[2]}")
        print(f"    Warehouse = {row[3]}")
except Exception as e:
    print(f"  Snowflake FAILED: {e}")

print("\n" + "=" * 60)
print("DIAGNOSTIC COMPLETE")
print("=" * 60)