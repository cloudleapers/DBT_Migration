-- ============================================================================
-- FILE:        00_setup.sql
-- PURPOSE:     One-shot Snowflake environment provisioning for the project.
-- TARGET:      Snowflake account (any region/edition)
-- RUNNER:      Run from Snowflake Worksheet as ACCOUNTADMIN role.
-- ESTIMATED:   < 1 minute
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   1. Switches to the ACCOUNTADMIN role (required for CREATE DATABASE)
--   2. Creates the HEALTHCARE_DW database (the entire warehouse)
--   3. Creates the 6 schemas used by dbt (RAW, STAGING, INTERMEDIATE,
--      MART, REPORTING, SNAPSHOTS)
--   4. Creates a small COMPUTE_WH warehouse (X-Small with auto-suspend)
--   5. Grants the warehouse to ACCOUNTADMIN
--   6. Verifies everything was created
-- ============================================================================
-- WHEN TO RE-RUN:
--   • First-time setup of the project on a fresh Snowflake trial account
--   • Re-creating a dropped environment
-- WHEN NOT TO RUN:
--   • This is destructive only if uncommented (CREATE DATABASE IF NOT EXISTS
--     is safe). Existing tables and data are preserved.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1: ROLE CONTEXT
-- ----------------------------------------------------------------------------
-- Ensure we have ACCOUNTADMIN privileges. Lower-privileged roles cannot
-- create databases or warehouses. For production deployments you would
-- create a dedicated DBT_ROLE with scoped permissions instead.
-- ----------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;


-- ----------------------------------------------------------------------------
-- PHASE 2: DATABASE CREATION
-- ----------------------------------------------------------------------------
-- HEALTHCARE_DW is the single analytical database for this project.
-- Every dbt schema, raw source table, and mart lives inside it.
-- IF NOT EXISTS makes this idempotent (safe to re-run).
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS HEALTHCARE_DW;
USE DATABASE HEALTHCARE_DW;


-- ----------------------------------------------------------------------------
-- PHASE 3: SCHEMA CREATION
-- ----------------------------------------------------------------------------
-- Six schemas, one per logical layer of the dbt project:
--
--   RAW           - Tables loaded by the Python ELT script directly from
--                   PostgreSQL and MySQL sources. NO transformations.
--   STAGING       - Cleaned, typed, renamed views (1:1 with sources).
--                   First dbt layer.
--   INTERMEDIATE  - Business logic and cross-domain joins. Bridges
--                   clinical and financial data.
--   MART          - Final star-schema tables (dimensions and facts).
--                   What BI tools query.
--   REPORTING     - Reserved for pre-aggregated BI cubes / metrics layer.
--   SNAPSHOTS     - Reserved for SCD Type 2 history tracking via dbt
--                   snapshots.
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE;
CREATE SCHEMA IF NOT EXISTS MART;
CREATE SCHEMA IF NOT EXISTS REPORTING;
CREATE SCHEMA IF NOT EXISTS SNAPSHOTS;


-- ----------------------------------------------------------------------------
-- PHASE 4: WAREHOUSE PROVISIONING
-- ----------------------------------------------------------------------------
-- COMPUTE_WH is the compute cluster dbt and queries run against.
--   - X-SMALL: cheapest tier, sufficient for our ~300K row scale
--   - AUTO_SUSPEND = 60: stops after 60s of inactivity to save credits
--   - AUTO_RESUME = TRUE: starts automatically on first query
--   - INITIALLY_SUSPENDED = FALSE: starts running immediately so first
--     dbt run does not have warm-up delay
-- ----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE     = 'X-SMALL'
  AUTO_SUSPEND       = 60
  AUTO_RESUME        = TRUE
  INITIALLY_SUSPENDED = FALSE
  COMMENT            = 'Default compute warehouse for healthcare_dbt project';


-- ----------------------------------------------------------------------------
-- PHASE 5: PERMISSION GRANTS
-- ----------------------------------------------------------------------------
-- ACCOUNTADMIN already implicitly owns everything, but explicit grants make
-- the script safe even if you switch roles later. For multi-team setups,
-- replace ACCOUNTADMIN with a dedicated DBT_ROLE.
-- ----------------------------------------------------------------------------
GRANT USAGE  ON WAREHOUSE COMPUTE_WH      TO ROLE ACCOUNTADMIN;
GRANT ALL    ON DATABASE  HEALTHCARE_DW   TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.RAW          TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.STAGING      TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.INTERMEDIATE TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.MART         TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.REPORTING    TO ROLE ACCOUNTADMIN;
GRANT ALL    ON SCHEMA HEALTHCARE_DW.SNAPSHOTS    TO ROLE ACCOUNTADMIN;


-- ----------------------------------------------------------------------------
-- PHASE 6: VERIFICATION
-- ----------------------------------------------------------------------------
-- Run these to confirm the environment is ready for dbt + the Python loader.
-- Expected:
--   - SHOW DATABASES includes HEALTHCARE_DW
--   - SHOW SCHEMAS shows 6 user schemas + INFORMATION_SCHEMA
--   - SHOW WAREHOUSES includes COMPUTE_WH
-- ----------------------------------------------------------------------------
SHOW DATABASES LIKE 'HEALTHCARE_DW';

SHOW SCHEMAS IN DATABASE HEALTHCARE_DW;

SHOW WAREHOUSES LIKE 'COMPUTE_WH';


-- ----------------------------------------------------------------------------
-- NEXT STEPS
-- ----------------------------------------------------------------------------
-- 1. Run sql/postgres/*.sql against your Supabase PostgreSQL database
-- 2. Run sql/mysql/*.sql against your Aiven MySQL database
-- 3. Run `python scripts/load_sources.py` to populate RAW
-- 4. Run `dbt run` to build STAGING, INTERMEDIATE, MART
-- 5. Run `dbt test` to validate
-- ============================================================================
