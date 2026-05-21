-- =====================================================================
-- DBT Migration Practice - SNOWFLAKE TARGET SETUP
-- Run as ACCOUNTADMIN (or a role with CREATE DATABASE)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS DBT_PRACTICE;
USE DATABASE DBT_PRACTICE;

-- Three-layer architecture
CREATE SCHEMA IF NOT EXISTS RAW;       -- 1:1 copy from Postgres (EL stage)
CREATE SCHEMA IF NOT EXISTS STAGING;   -- cleansed + typed (dbt staging models)
CREATE SCHEMA IF NOT EXISTS MARTS;     -- business-ready facts/dims (dbt mart models)

-- Warehouse + role (adjust to your account)
-- CREATE WAREHOUSE IF NOT EXISTS DBT_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60;
-- CREATE ROLE IF NOT EXISTS DBT_ROLE;
-- GRANT USAGE ON WAREHOUSE DBT_WH TO ROLE DBT_ROLE;
-- GRANT ALL ON DATABASE DBT_PRACTICE TO ROLE DBT_ROLE;
-- GRANT ALL ON ALL SCHEMAS IN DATABASE DBT_PRACTICE TO ROLE DBT_ROLE;

-- ---------------------------------------------------------------------
-- RAW layer — landed by Airbyte / Fivetran / custom Python from Postgres.
-- DBT does NOT write here; it only reads.
-- ---------------------------------------------------------------------
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS RAW_CUSTOMERS (
    customer_id   INTEGER,
    first_name    VARCHAR,
    last_name     VARCHAR,
    email         VARCHAR,
    phone         VARCHAR,
    country       VARCHAR,
    signup_date   VARCHAR,
    is_active     VARCHAR,
    created_at    TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW_PRODUCTS (
    product_id    INTEGER,
    product_name  VARCHAR,
    category      VARCHAR,
    unit_price    NUMBER(10,2),
    cost_price    NUMBER(10,2),
    in_stock      INTEGER,
    created_at    TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW_ORDERS (
    order_id      INTEGER,
    customer_id   INTEGER,
    product_id    INTEGER,
    order_date    DATE,
    quantity      INTEGER,
    unit_price    NUMBER(10,2),
    discount_pct  NUMBER(5,2),
    order_status  VARCHAR,
    created_at    TIMESTAMP_NTZ,
    _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
