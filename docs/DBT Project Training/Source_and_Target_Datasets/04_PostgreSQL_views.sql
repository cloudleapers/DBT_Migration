-- ============================================================================
-- FILE:        04_views.sql
-- DATABASE:    PostgreSQL (Supabase) - public schema
-- PURPOSE:     Create 12 reporting/analytical views on top of the source
--              tables. These views demonstrate "legacy reporting" that the
--              dbt project is migrating away from.
-- ESTIMATED:   < 5 seconds
-- ============================================================================
-- WHY VIEWS LIVE IN THE SOURCE DB:
--   In real migrations, you typically inherit a source system that already
--   has hundreds of reporting views. Part of the dbt migration project is
--   identifying which logic to keep, refactor, or replace.
-- ============================================================================
-- VIEWS CREATED:
--   1. vw_active_patients       - Currently active patients with computed age
--   2. vw_provider_summary      - Provider with specialty + facility joined
--   3. vw_encounter_details     - Encounter with patient + provider context
--   4. vw_diagnosis_rollup      - Diagnosis frequency analysis
--   5. vw_recent_visits         - Patients with visits in last year
--   6. vw_chronic_conditions    - Patients with chronic diagnoses
--   7. vw_pediatric_patients    - Patients under 18
--   8. vw_senior_patients       - Patients 65+
--   9. vw_high_risk_patients    - Multi-criteria risk scoring
--   10. vw_provider_workload    - Per-provider activity metrics
--   11. vw_facility_capacity    - Per-facility utilization
--   12. vw_encounter_stats_monthly - Monthly trend aggregations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- IDEMPOTENT RESET
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_active_patients         CASCADE;
DROP VIEW IF EXISTS vw_provider_summary        CASCADE;
DROP VIEW IF EXISTS vw_encounter_details       CASCADE;
DROP VIEW IF EXISTS vw_diagnosis_rollup        CASCADE;
DROP VIEW IF EXISTS vw_recent_visits           CASCADE;
DROP VIEW IF EXISTS vw_chronic_conditions      CASCADE;
DROP VIEW IF EXISTS vw_pediatric_patients      CASCADE;
DROP VIEW IF EXISTS vw_senior_patients         CASCADE;
DROP VIEW IF EXISTS vw_high_risk_patients      CASCADE;
DROP VIEW IF EXISTS vw_provider_workload       CASCADE;
DROP VIEW IF EXISTS vw_facility_capacity       CASCADE;
DROP VIEW IF EXISTS vw_encounter_stats_monthly CASCADE;


-- ----------------------------------------------------------------------------
-- VIEW 1: vw_active_patients
-- ----------------------------------------------------------------------------
-- Filter to only currently-active patients.
-- Computes age on the fly so it stays current.
-- Used downstream in: stg_pg_patients (similar logic), analyst ad-hoc.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_active_patients AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name,
  p.last_name,
  p.date_of_birth,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT AS age,
  p.gender,
  p.state_code,
  p.city,
  p.email,
  p.phone,
  p.primary_provider_id,
  p.registered_date
FROM patients p
WHERE p.is_active = TRUE;


-- ----------------------------------------------------------------------------
-- VIEW 2: vw_provider_summary
-- ----------------------------------------------------------------------------
-- Pre-joined provider with specialty and primary facility.
-- The "years_with_org" calculation is a common BI metric.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_provider_summary AS
SELECT
  pr.provider_id,
  pr.npi_number,
  pr.first_name || ' ' || pr.last_name AS provider_name,
  s.specialty_name,
  f.facility_name,
  f.city                               AS facility_city,
  f.state_code                         AS facility_state,
  pr.hire_date,
  EXTRACT(YEAR FROM AGE(pr.hire_date))::INT AS years_with_org,
  pr.is_active
FROM providers pr
JOIN specialty_types s ON pr.specialty_id = s.specialty_id
JOIN facilities f      ON pr.facility_id  = f.facility_id;


-- ----------------------------------------------------------------------------
-- VIEW 3: vw_encounter_details
-- ----------------------------------------------------------------------------
-- The "everything joined" encounter view that analysts love but ETL hates.
-- This pattern is exactly what dbt's int_encounter_full replaces with
-- proper layering.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_encounter_details AS
SELECT
  e.encounter_id,
  e.encounter_number,
  e.encounter_date,
  e.encounter_type,
  e.duration_minutes,
  e.chief_complaint,
  p.mrn,
  p.first_name || ' ' || p.last_name             AS patient_name,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT   AS patient_age,
  p.gender,
  pr.first_name || ' ' || pr.last_name           AS provider_name,
  s.specialty_name,
  f.facility_name,
  f.city                                         AS facility_city,
  f.state_code                                   AS facility_state
FROM encounters e
JOIN patients p        ON e.patient_id    = p.patient_id
JOIN providers pr      ON e.provider_id   = pr.provider_id
JOIN specialty_types s ON pr.specialty_id = s.specialty_id
JOIN facilities f      ON e.facility_id   = f.facility_id;


-- ----------------------------------------------------------------------------
-- VIEW 4: vw_diagnosis_rollup
-- ----------------------------------------------------------------------------
-- Diagnosis frequency analysis - which conditions does the practice see most?
-- Uses LEFT JOINs so codes with zero usage still appear (analytic completeness).
-- ----------------------------------------------------------------------------
CREATE VIEW vw_diagnosis_rollup AS
SELECT
  i.code         AS icd10_code,
  i.description,
  i.category,
  i.is_chronic,
  COUNT(d.diagnosis_id)             AS total_diagnoses,
  COUNT(DISTINCT e.patient_id)      AS unique_patients,
  COUNT(DISTINCT e.provider_id)     AS unique_providers,
  MIN(d.diagnosed_date)             AS first_diagnosed,
  MAX(d.diagnosed_date)             AS last_diagnosed
FROM icd10_codes i
LEFT JOIN encounter_diagnoses d ON i.code = d.icd10_code
LEFT JOIN encounters e          ON d.encounter_id = e.encounter_id
GROUP BY i.code, i.description, i.category, i.is_chronic;


-- ----------------------------------------------------------------------------
-- VIEW 5: vw_recent_visits
-- ----------------------------------------------------------------------------
-- Patients seen in the past year - drives "annual physical due" outreach.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_recent_visits AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name || ' ' || p.last_name      AS patient_name,
  MAX(e.encounter_date)                    AS last_visit_date,
  COUNT(e.encounter_id)                    AS visits_last_year,
  CURRENT_DATE - MAX(e.encounter_date)     AS days_since_last_visit
FROM patients p
JOIN encounters e ON p.patient_id = e.patient_id
WHERE e.encounter_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY p.patient_id, p.mrn, p.first_name, p.last_name;


-- ----------------------------------------------------------------------------
-- VIEW 6: vw_chronic_conditions
-- ----------------------------------------------------------------------------
-- Patients with chronic diagnoses, with conditions concatenated for display.
-- This is the legacy version of int_chronic_patients.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_chronic_conditions AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name || ' ' || p.last_name             AS patient_name,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT   AS age,
  STRING_AGG(DISTINCT i.description, '; ' ORDER BY i.description) AS chronic_conditions,
  COUNT(DISTINCT i.code)                         AS condition_count
FROM patients p
JOIN encounters e          ON p.patient_id   = e.patient_id
JOIN encounter_diagnoses d ON e.encounter_id = d.encounter_id
JOIN icd10_codes i         ON d.icd10_code   = i.code
WHERE i.is_chronic = TRUE
GROUP BY p.patient_id, p.mrn, p.first_name, p.last_name, p.date_of_birth;


-- ----------------------------------------------------------------------------
-- VIEW 7: vw_pediatric_patients
-- ----------------------------------------------------------------------------
-- Patients under 18 - drives pediatric outreach campaigns.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_pediatric_patients AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name || ' ' || p.last_name             AS patient_name,
  p.date_of_birth,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT   AS age,
  p.gender,
  pr.first_name || ' ' || pr.last_name           AS primary_provider
FROM patients p
LEFT JOIN providers pr ON p.primary_provider_id = pr.provider_id
WHERE EXTRACT(YEAR FROM AGE(p.date_of_birth)) < 18
  AND p.is_active = TRUE;


-- ----------------------------------------------------------------------------
-- VIEW 8: vw_senior_patients
-- ----------------------------------------------------------------------------
-- 65+ patients - drives Medicare wellness visits.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_senior_patients AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name || ' ' || p.last_name             AS patient_name,
  p.date_of_birth,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT   AS age,
  p.gender,
  pr.first_name || ' ' || pr.last_name           AS primary_provider
FROM patients p
LEFT JOIN providers pr ON p.primary_provider_id = pr.provider_id
WHERE EXTRACT(YEAR FROM AGE(p.date_of_birth)) >= 65
  AND p.is_active = TRUE;


-- ----------------------------------------------------------------------------
-- VIEW 9: vw_high_risk_patients
-- ----------------------------------------------------------------------------
-- Multi-criteria risk scoring:
--   - 2+ chronic conditions, OR
--   - 2+ ER visits, OR
--   - any severe allergy
-- HAVING clause filters at the aggregate level.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_high_risk_patients AS
SELECT
  p.patient_id,
  p.mrn,
  p.first_name || ' ' || p.last_name             AS patient_name,
  EXTRACT(YEAR FROM AGE(p.date_of_birth))::INT   AS age,
  COUNT(DISTINCT i.code) FILTER (WHERE i.is_chronic = TRUE)              AS chronic_condition_count,
  COUNT(DISTINCT e.encounter_id) FILTER (WHERE e.encounter_type = 'Emergency') AS er_visits_count,
  COUNT(DISTINCT al.allergy_id) FILTER (WHERE al.severity = 'Severe')    AS severe_allergy_count
FROM patients p
LEFT JOIN encounters e          ON p.patient_id   = e.patient_id
LEFT JOIN encounter_diagnoses d ON e.encounter_id = d.encounter_id
LEFT JOIN icd10_codes i         ON d.icd10_code   = i.code
LEFT JOIN allergies al          ON p.patient_id   = al.patient_id
GROUP BY p.patient_id, p.mrn, p.first_name, p.last_name, p.date_of_birth
HAVING
   COUNT(DISTINCT i.code) FILTER (WHERE i.is_chronic = TRUE) >= 2
   OR COUNT(DISTINCT e.encounter_id) FILTER (WHERE e.encounter_type = 'Emergency') >= 2
   OR COUNT(DISTINCT al.allergy_id) FILTER (WHERE al.severity = 'Severe') >= 1;


-- ----------------------------------------------------------------------------
-- VIEW 10: vw_provider_workload
-- ----------------------------------------------------------------------------
-- Per-provider productivity metrics. Drives staffing analytics.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_provider_workload AS
SELECT
  pr.provider_id,
  pr.first_name || ' ' || pr.last_name           AS provider_name,
  s.specialty_name,
  f.facility_name,
  COUNT(DISTINCT e.encounter_id)                 AS total_encounters,
  COUNT(DISTINCT e.patient_id)                   AS unique_patients,
  COUNT(DISTINCT e.encounter_date)               AS days_worked,
  COALESCE(AVG(e.duration_minutes), 0)::INT      AS avg_visit_duration_minutes,
  COUNT(DISTINCT pres.prescription_id)           AS prescriptions_written,
  COUNT(DISTINCT lo.lab_order_id)                AS lab_orders_placed
FROM providers pr
JOIN specialty_types s         ON pr.specialty_id = s.specialty_id
JOIN facilities f              ON pr.facility_id  = f.facility_id
LEFT JOIN encounters e         ON pr.provider_id  = e.provider_id
LEFT JOIN prescriptions pres   ON pr.provider_id  = pres.provider_id
LEFT JOIN lab_orders lo        ON pr.provider_id  = lo.provider_id
GROUP BY pr.provider_id, pr.first_name, pr.last_name, s.specialty_name, f.facility_name;


-- ----------------------------------------------------------------------------
-- VIEW 11: vw_facility_capacity
-- ----------------------------------------------------------------------------
-- Per-facility utilization, including 30-day and 12-month rolling encounters.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_facility_capacity AS
SELECT
  f.facility_id,
  f.facility_name,
  ft.type_name AS facility_type,
  f.city,
  f.state_code,
  f.capacity_beds,
  COUNT(DISTINCT pr.provider_id) AS total_providers,
  COUNT(DISTINCT e.encounter_id) FILTER (WHERE e.encounter_date >= CURRENT_DATE - INTERVAL '30 days') AS encounters_last_30_days,
  COUNT(DISTINCT e.encounter_id) FILTER (WHERE e.encounter_date >= CURRENT_DATE - INTERVAL '1 year')  AS encounters_last_year
FROM facilities f
JOIN facility_types ft  ON f.type_id = ft.type_id
LEFT JOIN providers pr  ON f.facility_id = pr.facility_id
LEFT JOIN encounters e  ON f.facility_id = e.facility_id
GROUP BY f.facility_id, f.facility_name, ft.type_name, f.city, f.state_code, f.capacity_beds;


-- ----------------------------------------------------------------------------
-- VIEW 12: vw_encounter_stats_monthly
-- ----------------------------------------------------------------------------
-- Monthly aggregations for trend dashboards.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_encounter_stats_monthly AS
SELECT
  DATE_TRUNC('month', encounter_date)::DATE AS month_start,
  encounter_type,
  COUNT(*)                                  AS total_encounters,
  COUNT(DISTINCT patient_id)                AS unique_patients,
  COUNT(DISTINCT provider_id)               AS unique_providers,
  AVG(duration_minutes)::INT                AS avg_duration_minutes,
  SUM(duration_minutes)                     AS total_minutes
FROM encounters
GROUP BY DATE_TRUNC('month', encounter_date), encounter_type
ORDER BY month_start DESC, encounter_type;


-- ----------------------------------------------------------------------------
-- VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected: total_views = 12
-- ----------------------------------------------------------------------------
SELECT 'Views created' AS status,
       COUNT(*)        AS total_views
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'vw_%';


-- ============================================================================
-- POSTGRES SOURCE LAYER COMPLETE
--   18 tables (5 lookups + 5 master + 8 transactional)
--   12 views
--   30 total source objects
-- NEXT: sql/mysql/01_reference_tables.sql
-- ============================================================================
