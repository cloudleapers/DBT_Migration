"""
Healthcare Data Migration - Source Loader
Extracts data from PostgreSQL + MySQL sources and loads into Snowflake RAW schema.
"""
import os
import time
from urllib.parse import quote_plus
import pandas as pd
from sqlalchemy import create_engine, text
from snowflake.sqlalchemy import URL as snowflake_url
from dotenv import load_dotenv

load_dotenv()

PG_TABLES = [
    'icd10_codes', 'cpt_codes', 'specialty_types', 'states', 'facility_types',
    'facilities', 'providers', 'patients', 'insurance_carriers', 'employees',
    'encounters', 'encounter_diagnoses', 'encounter_procedures',
    'prescriptions', 'lab_orders', 'lab_results', 'vitals', 'allergies'
]

MYSQL_TABLES = [
    'payer_types', 'insurance_plans', 'billing_codes',
    'claim_status_codes', 'adjustment_codes',
    'claims', 'claim_lines', 'payments', 'adjustments',
    'remittance_advice', 'claim_status_history', 'claim_attachments'
]


def get_pg_engine():
    pg_pwd = quote_plus(os.getenv('PG_PASSWORD'))
    pg_user = quote_plus(os.getenv('PG_USER'))
    url = (f"postgresql+psycopg2://{pg_user}:{pg_pwd}"
           f"@{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}"
           f"?sslmode=require")
    return create_engine(url)


def get_mysql_engine():
    mysql_pwd = quote_plus(os.getenv('MYSQL_PASSWORD'))
    mysql_user = quote_plus(os.getenv('MYSQL_USER'))
    url = (f"mysql+pymysql://{mysql_user}:{mysql_pwd}"
           f"@{os.getenv('MYSQL_HOST')}:{os.getenv('MYSQL_PORT')}/{os.getenv('MYSQL_DATABASE')}")
    return create_engine(url, connect_args={'ssl': {'ssl_disabled': False}})


def get_snowflake_engine():
    return create_engine(snowflake_url(
        account=os.getenv('SF_ACCOUNT'),
        user=os.getenv('SF_USER'),
        password=os.getenv('SF_PASSWORD'),
        role=os.getenv('SF_ROLE'),
        database=os.getenv('SF_DATABASE'),
        warehouse=os.getenv('SF_WAREHOUSE'),
        schema=os.getenv('SF_RAW_SCHEMA'),
    ))


def load_table(source_engine, snowflake_engine, source_table, target_prefix):
    target_table = f"{target_prefix}_{source_table}".upper()
    start = time.time()
    try:
        df = pd.read_sql_table(source_table, source_engine)
        row_count = len(df)
        print(f"  Read {row_count:>7,} rows from {source_table}")

        df.columns = [c.upper() for c in df.columns]

        df.to_sql(
            name=target_table,
            con=snowflake_engine,
            schema=os.getenv('SF_RAW_SCHEMA'),
            if_exists='replace',
            index=False,
            chunksize=10000,
            method='multi'
        )

        elapsed = time.time() - start
        print(f"  Loaded into Snowflake.{target_table} ({elapsed:.1f}s)")
        return row_count
    except Exception as e:
        print(f"  FAILED {source_table}: {e}")
        return 0


def main():
    print("=" * 60)
    print("HEALTHCARE DATA MIGRATION - SOURCE LOADER")
    print("=" * 60)

    print("\nConnecting to all databases...")
    pg = get_pg_engine()
    mysql = get_mysql_engine()
    sf = get_snowflake_engine()
    print("  All connections established")

    print("\n--- Loading PostgreSQL clinical data ---")
    pg_total = 0
    for tbl in PG_TABLES:
        pg_total += load_table(pg, sf, tbl, 'PG')

    print("\n--- Loading MySQL claims data ---")
    mysql_total = 0
    for tbl in MYSQL_TABLES:
        mysql_total += load_table(mysql, sf, tbl, 'MYSQL')

    print("\n" + "=" * 60)
    print(f"COMPLETE")
    print(f"  PostgreSQL rows loaded: {pg_total:,}")
    print(f"  MySQL rows loaded:      {mysql_total:,}")
    print(f"  Total rows in RAW:      {pg_total + mysql_total:,}")
    print("=" * 60)


if __name__ == '__main__':
    main()