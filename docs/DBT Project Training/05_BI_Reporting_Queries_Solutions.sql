-- ============================================================================
-- FILE:        06_daily_scenario_queries.sql
-- TARGET:      Snowflake HEALTHCARE_DW.MART schema
-- PURPOSE:     25+ business-scenario queries for the Week 5 training program.
--              Each query represents a real question stakeholders ask of a
--              healthcare data warehouse.
-- USAGE:       Run section-by-section, one section per training day (21-24).
-- ============================================================================
-- SECTIONS:
--   DAY 21 - Patient Analytics             (queries 1-7)
--   DAY 22 - Provider & Encounter Analytics (queries 8-14)
--   DAY 23 - Claim Financial Performance   (queries 15-20)
--   DAY 24 - Payer Analytics + AR & Aging  (queries 21-27)
-- ============================================================================
-- HOW TO USE:
--   1. Copy each query into Snowflake worksheet
--   2. Run and verify results
--   3. Modify the query to answer a follow-up question (extra credit)
--   4. Compare your results with a teammate
-- ============================================================================

USE DATABASE HEALTHCARE_DW;
USE SCHEMA MART;
USE WAREHOUSE COMPUTE_WH;


-- ============================================================================
-- DAY 21 - PATIENT ANALYTICS
-- ============================================================================
-- Theme: Understand the patient population, demographics, and clinical risk.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 1: Patient demographic distribution
-- BUSINESS QUESTION: How is our patient population distributed by region,
--                   age group, and gender? Used by population health team
--                   for outreach planning.
-- ----------------------------------------------------------------------------
SELECT
  region,
  age_group,
  gender,
  COUNT(*)                       AS patient_count,
  ROUND(AVG(age), 1)             AS avg_age,
  SUM(CASE WHEN is_chronic_patient THEN 1 ELSE 0 END) AS chronic_patients
FROM dim_patient
WHERE is_active = TRUE
GROUP BY region, age_group, gender
ORDER BY region, age_group, gender;


-- ----------------------------------------------------------------------------
-- QUERY 2: Top chronic conditions by patient count
-- BUSINESS QUESTION: Which chronic conditions affect the most patients?
--                   Drives chronic care management program priorities.
-- ----------------------------------------------------------------------------
SELECT
  chronic_category,
  COUNT(*)                       AS patient_count,
  ROUND(AVG(age), 1)             AS avg_age,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM dim_patient
GROUP BY chronic_category
ORDER BY patient_count DESC;


-- ----------------------------------------------------------------------------
-- QUERY 3: High-complexity patients with high outstanding balances
-- BUSINESS QUESTION: Which complex patients also have collection issues?
--                   Used by care management to prioritize outreach.
-- ----------------------------------------------------------------------------
SELECT
  p.patient_name,
  p.medical_record_number,
  p.age,
  p.chronic_category,
  p.chronic_condition_count,
  COUNT(DISTINCT c.claim_key)         AS claim_count,
  SUM(c.outstanding_balance)          AS total_outstanding
FROM dim_patient p
JOIN fct_claim c ON p.patient_key = c.patient_key
WHERE p.chronic_category = 'High Complexity'
  AND c.outstanding_balance > 0
GROUP BY 1, 2, 3, 4, 5
HAVING SUM(c.outstanding_balance) > 5000
ORDER BY total_outstanding DESC
LIMIT 25;


-- ----------------------------------------------------------------------------
-- QUERY 4: Senior patient utilization
-- BUSINESS QUESTION: How are senior patients (65+) utilizing the system?
--                   Drives Medicare wellness visit campaigns.
-- ----------------------------------------------------------------------------
SELECT
  p.region,
  COUNT(DISTINCT p.patient_key)              AS senior_patients,
  COUNT(DISTINCT e.encounter_key)            AS total_encounters,
  ROUND(COUNT(DISTINCT e.encounter_key) * 1.0 /
        NULLIF(COUNT(DISTINCT p.patient_key), 0), 2)  AS encounters_per_patient,
  SUM(e.total_billed)                        AS total_billed,
  SUM(e.total_collected)                     AS total_collected
FROM dim_patient p
LEFT JOIN fct_encounter e ON p.patient_key = e.patient_key
WHERE p.is_senior = TRUE
GROUP BY p.region
ORDER BY senior_patients DESC;


-- ----------------------------------------------------------------------------
-- QUERY 5: Pediatric patient profile
-- BUSINESS QUESTION: What does the pediatric patient population look like?
-- ----------------------------------------------------------------------------
SELECT
  p.region,
  p.age_group,
  COUNT(*)                       AS pediatric_patients,
  ROUND(AVG(p.age), 1)           AS avg_age,
  SUM(CASE WHEN p.is_chronic_patient THEN 1 ELSE 0 END) AS with_chronic_conditions
FROM dim_patient p
WHERE p.is_pediatric = TRUE
GROUP BY p.region, p.age_group
ORDER BY p.region, p.age_group;


-- ----------------------------------------------------------------------------
-- QUERY 6: Patient acquisition trend (registrations over time)
-- BUSINESS QUESTION: Are we growing or losing patients? Marketing impact?
-- ----------------------------------------------------------------------------
SELECT
  DATE_TRUNC('month', registered_date) AS registration_month,
  COUNT(*)                              AS new_patients,
  COUNT(DISTINCT region)                AS regions_active
FROM dim_patient
WHERE registered_date >= DATEADD('year', -2, CURRENT_DATE())
GROUP BY 1
ORDER BY 1 DESC
LIMIT 24;


-- ----------------------------------------------------------------------------
-- QUERY 7: Risk-stratified patient list for case management
-- BUSINESS QUESTION: Which patients need proactive outreach this month?
--                   Combines: chronic conditions + recent ER usage +
--                   outstanding balance.
-- ----------------------------------------------------------------------------
SELECT
  p.patient_name,
  p.medical_record_number,
  p.age,
  p.chronic_category,
  COUNT(DISTINCT CASE WHEN e.encounter_type = 'Emergency'
                       AND e.encounter_date >= DATEADD('day', -90, CURRENT_DATE())
                       THEN e.encounter_key END)        AS recent_er_visits,
  SUM(c.outstanding_balance)                            AS open_balance,
  -- Risk score: chronic count * 10 + recent_er * 25 + (open_balance / 1000)
  (p.chronic_condition_count * 10) +
  (COUNT(DISTINCT CASE WHEN e.encounter_type = 'Emergency'
                        AND e.encounter_date >= DATEADD('day', -90, CURRENT_DATE())
                        THEN e.encounter_key END) * 25) +
  (COALESCE(SUM(c.outstanding_balance), 0) / 1000)      AS risk_score
FROM dim_patient p
LEFT JOIN fct_encounter e ON p.patient_key = e.patient_key
LEFT JOIN fct_claim c     ON p.patient_key = c.patient_key
GROUP BY 1, 2, 3, 4, p.chronic_condition_count
HAVING risk_score > 30
ORDER BY risk_score DESC
LIMIT 50;


-- ============================================================================
-- DAY 22 - PROVIDER & ENCOUNTER ANALYTICS
-- ============================================================================
-- Theme: Provider productivity, encounter patterns, facility utilization.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 8: Provider productivity scorecard
-- BUSINESS QUESTION: Which providers see the most patients? Drives staffing.
-- ----------------------------------------------------------------------------
SELECT
  p.provider_name,
  p.specialty_name,
  p.facility_name,
  p.experience_level,
  COUNT(DISTINCT e.encounter_key)            AS encounters,
  COUNT(DISTINCT e.patient_key)              AS unique_patients,
  ROUND(AVG(e.duration_minutes), 0)          AS avg_visit_minutes,
  SUM(e.total_billed)                        AS total_billed,
  SUM(e.total_collected)                     AS total_collected
FROM dim_provider p
JOIN fct_encounter e ON p.provider_key = e.provider_key
GROUP BY 1, 2, 3, 4
ORDER BY encounters DESC
LIMIT 20;


-- ----------------------------------------------------------------------------
-- QUERY 9: Specialty mix analysis
-- BUSINESS QUESTION: How do encounter types vary by specialty?
-- ----------------------------------------------------------------------------
SELECT
  p.specialty_name,
  e.encounter_type,
  COUNT(*)                                   AS encounters,
  ROUND(AVG(e.duration_minutes), 0)          AS avg_minutes,
  ROUND(AVG(e.total_billed), 2)              AS avg_billed,
  ROUND(AVG(e.collection_rate_pct), 2)       AS avg_collection_rate
FROM dim_provider p
JOIN fct_encounter e ON p.provider_key = e.provider_key
GROUP BY 1, 2
ORDER BY p.specialty_name, encounters DESC;


-- ----------------------------------------------------------------------------
-- QUERY 10: Facility capacity utilization
-- BUSINESS QUESTION: Which facilities are over/under utilized?
-- ----------------------------------------------------------------------------
SELECT
  f.facility_name,
  f.facility_type_name,
  f.facility_size,
  f.region,
  COUNT(DISTINCT e.encounter_key)            AS total_encounters,
  COUNT(DISTINCT e.encounter_key) FILTER (WHERE e.encounter_date >= DATEADD('day', -30, CURRENT_DATE())) AS encounters_last_30d,
  COUNT(DISTINCT e.provider_key)             AS active_providers,
  ROUND(COUNT(DISTINCT e.encounter_key) * 1.0 /
        NULLIF(COUNT(DISTINCT e.provider_key), 0), 1) AS encounters_per_provider
FROM dim_facility f
LEFT JOIN fct_encounter e ON f.facility_key = e.facility_key
GROUP BY 1, 2, 3, 4
ORDER BY total_encounters DESC;


-- ----------------------------------------------------------------------------
-- QUERY 11: Acute care encounter analysis
-- BUSINESS QUESTION: How are emergency and urgent care visits distributed?
-- ----------------------------------------------------------------------------
SELECT
  e.encounter_type,
  COUNT(*)                                   AS encounter_count,
  COUNT(DISTINCT e.patient_key)              AS unique_patients,
  ROUND(AVG(e.duration_minutes), 0)          AS avg_minutes,
  ROUND(AVG(e.total_billed), 2)              AS avg_billed,
  SUM(e.total_billed)                        AS total_billed,
  SUM(e.total_collected)                     AS total_collected,
  ROUND(SUM(e.total_collected) * 100.0 /
        NULLIF(SUM(e.total_billed), 0), 2)   AS collection_rate_pct
FROM fct_encounter e
GROUP BY 1
ORDER BY encounter_count DESC;


-- ----------------------------------------------------------------------------
-- QUERY 12: Provider tenure vs productivity
-- BUSINESS QUESTION: Do senior providers see more patients? Better outcomes?
-- ----------------------------------------------------------------------------
SELECT
  p.experience_level,
  COUNT(DISTINCT p.provider_key)             AS provider_count,
  COUNT(DISTINCT e.encounter_key)            AS total_encounters,
  ROUND(COUNT(DISTINCT e.encounter_key) * 1.0 /
        NULLIF(COUNT(DISTINCT p.provider_key), 0), 1) AS encounters_per_provider,
  ROUND(AVG(e.duration_minutes), 0)          AS avg_visit_minutes,
  ROUND(AVG(e.collection_rate_pct), 2)       AS avg_collection_rate
FROM dim_provider p
LEFT JOIN fct_encounter e ON p.provider_key = e.provider_key
GROUP BY 1
ORDER BY
  CASE p.experience_level
    WHEN 'Senior' THEN 1
    WHEN 'Mid-Level' THEN 2
    WHEN 'Junior' THEN 3
  END;


-- ----------------------------------------------------------------------------
-- QUERY 13: Monthly encounter trend
-- BUSINESS QUESTION: Is encounter volume growing or shrinking? Seasonality?
-- ----------------------------------------------------------------------------
SELECT
  d.year_month                               AS month,
  COUNT(DISTINCT e.encounter_key)            AS total_encounters,
  COUNT(DISTINCT e.patient_key)              AS unique_patients,
  COUNT(DISTINCT e.provider_key)             AS active_providers,
  ROUND(AVG(e.duration_minutes), 0)          AS avg_minutes,
  SUM(e.total_billed)                        AS total_billed
FROM fct_encounter e
JOIN dim_date d ON e.date_key = d.date_key
WHERE d.full_date >= DATEADD('year', -2, CURRENT_DATE())
GROUP BY 1
ORDER BY 1 DESC;


-- ----------------------------------------------------------------------------
-- QUERY 14: Top diagnoses by encounter
-- BUSINESS QUESTION: What are clinicians treating most often?
-- ----------------------------------------------------------------------------
SELECT
  dx.diagnosis_key                           AS icd10_code,
  dx.diagnosis_description,
  dx.disease_category,
  dx.is_chronic,
  dx.risk_category,
  COUNT(DISTINCT e.encounter_key)            AS encounters,
  COUNT(DISTINCT e.patient_key)              AS unique_patients
FROM dim_diagnosis dx
JOIN fct_encounter e ON dx.diagnosis_key = e.primary_diagnosis_key
GROUP BY 1, 2, 3, 4, 5
ORDER BY encounters DESC
LIMIT 15;


-- ============================================================================
-- DAY 23 - CLAIM FINANCIAL PERFORMANCE
-- ============================================================================
-- Theme: Revenue cycle management, denials, payment patterns.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 15: Claim status distribution and value
-- BUSINESS QUESTION: How healthy is our claim portfolio overall?
-- ----------------------------------------------------------------------------
SELECT
  current_status_name                        AS status,
  COUNT(*)                                   AS claim_count,
  SUM(total_charge_amount)                   AS total_billed,
  SUM(total_paid_amount)                     AS total_paid,
  SUM(outstanding_balance)                   AS outstanding,
  ROUND(AVG(payment_ratio_pct), 2)           AS avg_payment_ratio
FROM fct_claim
GROUP BY 1
ORDER BY claim_count DESC;


-- ----------------------------------------------------------------------------
-- QUERY 16: Denial rate by payer segment
-- BUSINESS QUESTION: Which payer segments deny most often?
-- ----------------------------------------------------------------------------
SELECT
  pay.payer_segment,
  COUNT(*)                                   AS total_claims,
  SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) AS denied_claims,
  ROUND(SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*), 2)                         AS denial_rate_pct,
  SUM(CASE WHEN c.current_status_code = 'DENIED' THEN c.total_charge_amount ELSE 0 END) AS denied_dollars
FROM fct_claim c
JOIN dim_payer pay ON c.payer_key = pay.payer_key
GROUP BY 1
ORDER BY denial_rate_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 17: Top denial reasons (drill-down)
-- BUSINESS QUESTION: What specific denial codes are costing us the most?
-- ----------------------------------------------------------------------------
SELECT
  CASE
    WHEN has_medical_necessity_denial THEN 'Medical Necessity'
    WHEN has_coding_issue THEN 'Coding Issue'
    ELSE 'Other'
  END                                        AS denial_category,
  COUNT(*)                                   AS denied_claim_count,
  SUM(total_charge_amount)                   AS total_denied,
  ROUND(AVG(total_charge_amount), 2)         AS avg_charge
FROM fct_claim
WHERE current_status_code = 'DENIED'
GROUP BY 1
ORDER BY total_denied DESC;


-- ----------------------------------------------------------------------------
-- QUERY 18: Clean claim rate by carrier
-- BUSINESS QUESTION: Where are we filing dirty claims most often?
-- ----------------------------------------------------------------------------
SELECT
  pay.carrier_name,
  pay.payer_segment,
  COUNT(*)                                   AS total_claims,
  SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) AS clean_claims,
  ROUND(SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS clean_claim_rate_pct
FROM fct_claim c
JOIN dim_payer pay ON c.payer_key = pay.payer_key
GROUP BY 1, 2
HAVING COUNT(*) > 50
ORDER BY clean_claim_rate_pct ASC;


-- ----------------------------------------------------------------------------
-- QUERY 19: Days to submission (filing efficiency)
-- BUSINESS QUESTION: Are we filing claims promptly? Filing limit risk?
-- ----------------------------------------------------------------------------
SELECT
  CASE
    WHEN days_to_submit <= 1 THEN 'Same Day / Next Day'
    WHEN days_to_submit <= 7 THEN '2-7 days'
    WHEN days_to_submit <= 14 THEN '8-14 days'
    WHEN days_to_submit <= 30 THEN '15-30 days'
    ELSE '30+ days'
  END                                        AS submission_window,
  COUNT(*)                                   AS claim_count,
  ROUND(AVG(payment_ratio_pct), 2)           AS avg_payment_ratio,
  SUM(CASE WHEN current_status_code = 'PAID' THEN 1 ELSE 0 END) AS paid_count,
  ROUND(SUM(CASE WHEN current_status_code = 'PAID' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS paid_rate_pct
FROM fct_claim
GROUP BY 1
ORDER BY
  CASE
    WHEN days_to_submit <= 1 THEN 1
    WHEN days_to_submit <= 7 THEN 2
    WHEN days_to_submit <= 14 THEN 3
    WHEN days_to_submit <= 30 THEN 4
    ELSE 5
  END;


-- ----------------------------------------------------------------------------
-- QUERY 20: Provider-level revenue cycle scorecard
-- BUSINESS QUESTION: Which providers have the strongest revenue cycle?
-- ----------------------------------------------------------------------------
SELECT
  p.provider_name,
  p.specialty_name,
  COUNT(*)                                   AS claims,
  SUM(c.total_charge_amount)                 AS billed,
  SUM(c.total_paid_amount)                   AS collected,
  ROUND(SUM(c.total_paid_amount) * 100.0 /
        NULLIF(SUM(c.total_charge_amount), 0), 2) AS collection_rate_pct,
  SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) AS clean_claims,
  ROUND(SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*), 2)                         AS clean_claim_rate_pct,
  SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) AS denials,
  ROUND(SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*), 2)                         AS denial_rate_pct
FROM fct_claim c
JOIN dim_provider p ON c.provider_key = p.provider_key
GROUP BY 1, 2
HAVING COUNT(*) > 100
ORDER BY collection_rate_pct DESC
LIMIT 25;


-- ============================================================================
-- DAY 24 - PAYER ANALYTICS + AR & AGING
-- ============================================================================
-- Theme: Payer performance, accounts receivable health, aging analysis.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 21: Carrier collection rate ranking
-- BUSINESS QUESTION: Which carriers pay the best? Worst?
-- ----------------------------------------------------------------------------
SELECT
  pay.carrier_name,
  pay.payer_segment,
  COUNT(*)                                   AS total_claims,
  SUM(c.total_charge_amount)                 AS total_billed,
  SUM(c.total_paid_amount)                   AS total_collected,
  ROUND(SUM(c.total_paid_amount) * 100.0 /
        NULLIF(SUM(c.total_charge_amount), 0), 2) AS collection_rate_pct,
  ROUND(AVG(c.days_to_submit), 1)            AS avg_days_to_submit
FROM fct_claim c
JOIN dim_payer pay ON c.payer_key = pay.payer_key
GROUP BY 1, 2
ORDER BY collection_rate_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 22: AR aging summary - outstanding balance by bucket
-- BUSINESS QUESTION: How much money is in each aging bucket?
-- ----------------------------------------------------------------------------
SELECT
  aging_bucket,
  COUNT(*)                                   AS claim_count,
  SUM(outstanding_balance)                   AS total_outstanding,
  ROUND(SUM(outstanding_balance) * 100.0 /
        SUM(SUM(outstanding_balance)) OVER (), 2) AS pct_of_ar,
  ROUND(AVG(outstanding_balance), 2)         AS avg_balance
FROM fct_claim
WHERE outstanding_balance > 0
GROUP BY 1
ORDER BY
  CASE aging_bucket
    WHEN 'No Balance' THEN 0
    WHEN '0-30 days' THEN 1
    WHEN '31-60 days' THEN 2
    WHEN '61-90 days' THEN 3
    WHEN '91-120 days' THEN 4
    WHEN '120+ days' THEN 5
  END;


-- ----------------------------------------------------------------------------
-- QUERY 23: AR aging by carrier
-- BUSINESS QUESTION: Which carriers have the most aged AR?
-- ----------------------------------------------------------------------------
SELECT
  pay.carrier_name,
  SUM(CASE WHEN c.aging_bucket = '0-30 days'   THEN c.outstanding_balance ELSE 0 END) AS bucket_0_30,
  SUM(CASE WHEN c.aging_bucket = '31-60 days'  THEN c.outstanding_balance ELSE 0 END) AS bucket_31_60,
  SUM(CASE WHEN c.aging_bucket = '61-90 days'  THEN c.outstanding_balance ELSE 0 END) AS bucket_61_90,
  SUM(CASE WHEN c.aging_bucket = '91-120 days' THEN c.outstanding_balance ELSE 0 END) AS bucket_91_120,
  SUM(CASE WHEN c.aging_bucket = '120+ days'   THEN c.outstanding_balance ELSE 0 END) AS bucket_120_plus,
  SUM(c.outstanding_balance)                 AS total_ar
FROM fct_claim c
JOIN dim_payer pay ON c.payer_key = pay.payer_key
WHERE c.outstanding_balance > 0
GROUP BY 1
ORDER BY total_ar DESC
LIMIT 15;


-- ----------------------------------------------------------------------------
-- QUERY 24: Plan-level performance
-- BUSINESS QUESTION: How do specific insurance plans compare on payment?
-- ----------------------------------------------------------------------------
SELECT
  pay.plan_name,
  pay.plan_type,
  pay.deductible_tier,
  COUNT(*)                                   AS claims,
  SUM(c.total_charge_amount)                 AS billed,
  SUM(c.total_paid_amount)                   AS collected,
  ROUND(SUM(c.total_paid_amount) * 100.0 /
        NULLIF(SUM(c.total_charge_amount), 0), 2) AS collection_rate_pct
FROM fct_claim c
JOIN dim_payer pay ON c.payer_key = pay.payer_key
GROUP BY 1, 2, 3
HAVING COUNT(*) > 100
ORDER BY collection_rate_pct DESC;


-- ----------------------------------------------------------------------------
-- QUERY 25: Monthly collections trend
-- BUSINESS QUESTION: Is monthly cash flow growing? Seasonality?
-- ----------------------------------------------------------------------------
SELECT
  d.year_month                               AS month,
  COUNT(DISTINCT p.payment_key)              AS payment_count,
  SUM(p.payment_amount)                      AS collections,
  ROUND(AVG(p.payment_amount), 2)            AS avg_payment,
  COUNT(DISTINCT p.payer_carrier_id)         AS active_carriers
FROM fct_payment p
JOIN dim_date d ON p.payment_date_key = d.date_key
WHERE p.is_posted = TRUE
  AND d.full_date >= DATEADD('year', -2, CURRENT_DATE())
GROUP BY 1
ORDER BY 1 DESC
LIMIT 24;


-- ----------------------------------------------------------------------------
-- QUERY 26: Underpayment / overpayment analysis
-- BUSINESS QUESTION: Are we receiving the contracted amounts? Variance?
-- ----------------------------------------------------------------------------
SELECT
  reconciliation_status,
  COUNT(*)                                   AS payment_count,
  SUM(payment_amount)                        AS total_paid,
  SUM(variance_from_allowed)                 AS total_variance,
  ROUND(AVG(variance_from_allowed), 2)       AS avg_variance,
  ROUND(AVG(days_to_post), 1)                AS avg_days_to_post
FROM fct_payment
WHERE is_posted = TRUE
GROUP BY 1
ORDER BY total_variance DESC;


-- ----------------------------------------------------------------------------
-- QUERY 27: Top patients by outstanding balance (collection priorities)
-- BUSINESS QUESTION: Which patients should our collections team contact?
-- ----------------------------------------------------------------------------
SELECT
  p.patient_name,
  p.medical_record_number,
  p.email,
  p.phone,
  p.region,
  COUNT(DISTINCT c.claim_key)                AS open_claims,
  SUM(c.outstanding_balance)                 AS total_owed,
  MAX(c.aging_bucket)                        AS oldest_bucket,
  MIN(d.full_date)                           AS oldest_service_date
FROM dim_patient p
JOIN fct_claim c   ON p.patient_key = c.patient_key
JOIN dim_date d    ON c.service_date_key = d.date_key
WHERE c.outstanding_balance > 0
  AND c.current_status_code NOT IN ('VOID', 'REJECTED')
GROUP BY 1, 2, 3, 4, 5
HAVING SUM(c.outstanding_balance) > 1000
ORDER BY total_owed DESC
LIMIT 50;


-- ============================================================================
-- BONUS - CROSS-DOMAIN QUERIES (Day 25 prep / capstone inspiration)
-- ============================================================================


-- ----------------------------------------------------------------------------
-- BONUS 1: Clinical-financial correlation
-- "Do chronic patients drive disproportionate revenue or denials?"
-- ----------------------------------------------------------------------------
SELECT
  p.chronic_category,
  COUNT(DISTINCT p.patient_key)              AS patients,
  COUNT(DISTINCT c.claim_key)                AS claims,
  ROUND(COUNT(DISTINCT c.claim_key) * 1.0 /
        NULLIF(COUNT(DISTINCT p.patient_key), 0), 2) AS claims_per_patient,
  SUM(c.total_charge_amount)                 AS billed,
  SUM(c.total_paid_amount)                   AS collected,
  ROUND(SUM(c.total_paid_amount) * 100.0 /
        NULLIF(SUM(c.total_charge_amount), 0), 2) AS collection_rate_pct,
  SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) AS denials,
  ROUND(SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(DISTINCT c.claim_key), 0), 2) AS denial_rate_pct
FROM dim_patient p
LEFT JOIN fct_claim c ON p.patient_key = c.patient_key
GROUP BY 1
ORDER BY billed DESC;


-- ----------------------------------------------------------------------------
-- BONUS 2: ED utilization without follow-up
-- "Patients who used ED but had no PCP visit in last 90 days"
-- This identifies potential care coordination gaps.
-- ----------------------------------------------------------------------------
WITH ed_patients AS (
  SELECT DISTINCT patient_key, MAX(encounter_date) AS last_ed_date
  FROM fct_encounter
  WHERE encounter_type = 'Emergency'
    AND encounter_date >= DATEADD('day', -180, CURRENT_DATE())
  GROUP BY patient_key
),
follow_up_patients AS (
  SELECT DISTINCT patient_key
  FROM fct_encounter e
  WHERE encounter_type IN ('Office Visit', 'Wellness')
    AND encounter_date >= DATEADD('day', -90, CURRENT_DATE())
)
SELECT
  ed.patient_key,
  p.patient_name,
  p.medical_record_number,
  p.region,
  ed.last_ed_date,
  DATEDIFF('day', ed.last_ed_date, CURRENT_DATE()) AS days_since_ed
FROM ed_patients ed
JOIN dim_patient p ON ed.patient_key = p.patient_key
LEFT JOIN follow_up_patients fp ON ed.patient_key = fp.patient_key
WHERE fp.patient_key IS NULL
ORDER BY ed.last_ed_date DESC
LIMIT 50;


-- ----------------------------------------------------------------------------
-- BONUS 3: Revenue cycle "leakage" detection
-- "Encounters where charges exist but no claim was filed"
-- ----------------------------------------------------------------------------
SELECT
  e.encounter_date,
  p.provider_name,
  pat.medical_record_number,
  e.encounter_type,
  e.total_procedure_charges,
  e.collection_status
FROM fct_encounter e
JOIN dim_provider p   ON e.provider_key = p.provider_key
JOIN dim_patient pat  ON e.patient_key  = pat.patient_key
WHERE e.collection_status = 'No Claim Filed'
  AND e.total_procedure_charges > 0
  AND e.encounter_date >= DATEADD('day', -90, CURRENT_DATE())
ORDER BY e.total_procedure_charges DESC
LIMIT 50;


-- ============================================================================
-- END OF SCENARIO QUERIES
-- ============================================================================
-- For Day 25 capstone, modify these queries or create new ones that
-- demonstrate end-to-end mastery of the warehouse.
-- ============================================================================
