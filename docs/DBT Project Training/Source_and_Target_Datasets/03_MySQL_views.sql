-- ============================================================================
-- FILE:        03_views.sql
-- DATABASE:    MySQL (Aiven) - HealthCare_THP
-- PURPOSE:     Create 13 reporting views on the claims/financial tables.
-- ESTIMATED:   < 5 seconds
-- ============================================================================
-- VIEWS CREATED:
--   1. vw_claim_summary           - Claim with patient + provider context
--   2. vw_payment_reconciliation  - Payment vs charge reconciliation
--   3. vw_denied_claims           - Denials with reasons
--   4. vw_outstanding_balances    - Open AR
--   5. vw_paid_claims             - Fully paid claims
--   6. vw_partial_payments        - Partially paid claims
--   7. vw_aged_receivables        - Aging buckets
--   8. vw_top_denials             - Most common denial reasons
--   9. vw_payer_performance       - Carrier metrics
--   10. vw_claim_aging_buckets    - Aging distribution
--   11. vw_clean_claim_rate       - Clean claim percentage by carrier
--   12. vw_first_pass_resolution  - First-pass resolution rate
--   13. vw_monthly_collections    - Monthly collection trend
-- ============================================================================
-- DEPENDENCIES:
--   01_reference_tables.sql AND 02_transactional_tables.sql must run first.
-- ============================================================================

USE HealthCare_THP;

-- ----------------------------------------------------------------------------
-- IDEMPOTENT RESET
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_claim_summary;
DROP VIEW IF EXISTS vw_payment_reconciliation;
DROP VIEW IF EXISTS vw_denied_claims;
DROP VIEW IF EXISTS vw_outstanding_balances;
DROP VIEW IF EXISTS vw_paid_claims;
DROP VIEW IF EXISTS vw_partial_payments;
DROP VIEW IF EXISTS vw_aged_receivables;
DROP VIEW IF EXISTS vw_top_denials;
DROP VIEW IF EXISTS vw_payer_performance;
DROP VIEW IF EXISTS vw_claim_aging_buckets;
DROP VIEW IF EXISTS vw_clean_claim_rate;
DROP VIEW IF EXISTS vw_first_pass_resolution;
DROP VIEW IF EXISTS vw_monthly_collections;


-- ----------------------------------------------------------------------------
-- VIEW 1: vw_claim_summary
-- ----------------------------------------------------------------------------
-- The "everything joined" claim view used by analyst queries.
-- Plan + status code joined for human-readable display.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_claim_summary AS
SELECT
  c.claim_id, c.claim_number, c.patient_id, c.patient_mrn,
  c.encounter_id, c.provider_id, c.provider_npi, c.facility_id,
  c.carrier_id, c.plan_id, p.plan_name, p.plan_type,
  c.service_date, c.submission_date,
  DATEDIFF(c.submission_date, c.service_date)             AS days_to_submit,
  c.total_charge_amount, c.total_allowed_amount, c.total_paid_amount,
  c.total_charge_amount - c.total_paid_amount             AS outstanding_balance,
  c.patient_responsibility,
  c.current_status_code, sc.status_name,
  c.primary_diagnosis, c.claim_type, c.is_clean_claim, c.filing_indicator
FROM claims c
LEFT JOIN insurance_plans p     ON c.plan_id = p.plan_id
LEFT JOIN claim_status_codes sc ON c.current_status_code = sc.status_code;


-- ----------------------------------------------------------------------------
-- VIEW 2: vw_payment_reconciliation
-- ----------------------------------------------------------------------------
-- Payment events with the source claim charge for variance analysis.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_payment_reconciliation AS
SELECT
  pay.payment_id, pay.claim_id, c.claim_number, pay.payment_number,
  pay.carrier_id, c.total_charge_amount AS claim_charge,
  c.total_allowed_amount AS claim_allowed, pay.payment_amount,
  c.total_charge_amount - pay.payment_amount AS variance_from_charge,
  pay.payment_date, pay.payment_method,
  pay.is_posted, pay.posted_date,
  CASE
    WHEN pay.posted_date IS NULL THEN NULL
    ELSE DATEDIFF(pay.posted_date, pay.payment_date)
  END AS days_to_post
FROM payments pay
JOIN claims c ON pay.claim_id = c.claim_id;


-- ----------------------------------------------------------------------------
-- VIEW 3: vw_denied_claims
-- ----------------------------------------------------------------------------
-- All denied claims with the denial reason joined in.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_denied_claims AS
SELECT
  c.claim_id, c.claim_number, c.patient_id, c.carrier_id, c.plan_id,
  c.service_date, c.submission_date, c.total_charge_amount,
  c.primary_diagnosis,
  a.adjustment_code, ac.description AS denial_reason, ac.category AS denial_category
FROM claims c
LEFT JOIN adjustments a       ON c.claim_id = a.claim_id
LEFT JOIN adjustment_codes ac ON a.adjustment_code = ac.code
WHERE c.current_status_code = 'DENIED'
  AND ac.is_denial = TRUE;


-- ----------------------------------------------------------------------------
-- VIEW 4: vw_outstanding_balances
-- ----------------------------------------------------------------------------
-- Open accounts receivable - claims with money still owed.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_outstanding_balances AS
SELECT
  c.claim_id, c.claim_number, c.patient_id, c.patient_mrn,
  c.carrier_id, c.service_date, c.submission_date,
  c.total_charge_amount, c.total_paid_amount,
  c.total_charge_amount - c.total_paid_amount AS outstanding_amount,
  c.current_status_code,
  DATEDIFF(CURDATE(), c.submission_date) AS days_outstanding
FROM claims c
WHERE c.total_charge_amount > c.total_paid_amount
  AND c.current_status_code NOT IN ('VOID', 'REJECTED');


-- ----------------------------------------------------------------------------
-- VIEW 5: vw_paid_claims
-- ----------------------------------------------------------------------------
-- All fully-paid claims - the cleanest revenue events.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_paid_claims AS
SELECT c.claim_id, c.claim_number, c.patient_id, c.carrier_id, c.plan_id,
       c.service_date, c.submission_date, c.total_charge_amount,
       c.total_allowed_amount, c.total_paid_amount,
       DATEDIFF(c.submission_date, c.service_date) AS days_to_submit
FROM claims c
WHERE c.current_status_code = 'PAID';


-- ----------------------------------------------------------------------------
-- VIEW 6: vw_partial_payments
-- ----------------------------------------------------------------------------
-- Partial payments warrant follow-up - someone owes more.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_partial_payments AS
SELECT c.claim_id, c.claim_number, c.carrier_id,
       c.total_charge_amount, c.total_allowed_amount, c.total_paid_amount,
       c.total_charge_amount - c.total_paid_amount AS balance_owed,
       ROUND((c.total_paid_amount / c.total_charge_amount) * 100, 2) AS payment_ratio_pct
FROM claims c
WHERE c.current_status_code = 'PARTIAL'
  AND c.total_paid_amount > 0;


-- ----------------------------------------------------------------------------
-- VIEW 7: vw_aged_receivables
-- ----------------------------------------------------------------------------
-- Aging buckets - the standard AR aging report.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_aged_receivables AS
SELECT
  c.claim_id, c.claim_number, c.carrier_id,
  c.total_charge_amount - c.total_paid_amount AS balance,
  DATEDIFF(CURDATE(), c.submission_date) AS days_old,
  CASE
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 30 THEN '0-30 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 60 THEN '31-60 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 90 THEN '61-90 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 120 THEN '91-120 days'
    ELSE '120+ days'
  END AS aging_bucket
FROM claims c
WHERE c.total_charge_amount > c.total_paid_amount
  AND c.current_status_code NOT IN ('VOID', 'REJECTED', 'PAID');


-- ----------------------------------------------------------------------------
-- VIEW 8: vw_top_denials
-- ----------------------------------------------------------------------------
-- Frequency analysis of denial reasons - drives revenue cycle improvements.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_top_denials AS
SELECT
  ac.code AS denial_code, ac.description, ac.category,
  COUNT(*)                       AS denial_count,
  SUM(a.adjustment_amount)       AS total_denied_amount,
  COUNT(DISTINCT a.claim_id)     AS affected_claims,
  COUNT(DISTINCT c.carrier_id)   AS carriers_with_denial
FROM adjustments a
JOIN adjustment_codes ac ON a.adjustment_code = ac.code
JOIN claims c            ON a.claim_id = c.claim_id
WHERE ac.is_denial = TRUE
GROUP BY ac.code, ac.description, ac.category;


-- ----------------------------------------------------------------------------
-- VIEW 9: vw_payer_performance
-- ----------------------------------------------------------------------------
-- Carrier-level KPIs: collection rate, average days to pay, denial rate.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_payer_performance AS
SELECT
  c.carrier_id,
  COUNT(*)                                   AS total_claims,
  SUM(c.total_charge_amount)                 AS total_billed,
  SUM(c.total_paid_amount)                   AS total_collected,
  ROUND(SUM(c.total_paid_amount) * 100.0 /
        NULLIF(SUM(c.total_charge_amount), 0), 2)  AS collection_rate_pct,
  AVG(CASE
        WHEN c.current_status_code IN ('PAID','PARTIAL')
        THEN DATEDIFF(c.submission_date, c.service_date)
      END)                                   AS avg_days_to_submit,
  SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) AS denied_claims,
  ROUND(SUM(CASE WHEN c.current_status_code = 'DENIED' THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*), 2)                         AS denial_rate_pct
FROM claims c
GROUP BY c.carrier_id;


-- ----------------------------------------------------------------------------
-- VIEW 10: vw_claim_aging_buckets
-- ----------------------------------------------------------------------------
-- Aggregate aging buckets - how much money in each bucket.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_claim_aging_buckets AS
SELECT
  CASE
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 30 THEN '0-30 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 60 THEN '31-60 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 90 THEN '61-90 days'
    WHEN DATEDIFF(CURDATE(), c.submission_date) <= 120 THEN '91-120 days'
    ELSE '120+ days'
  END                                                AS aging_bucket,
  COUNT(*)                                           AS claim_count,
  SUM(c.total_charge_amount - c.total_paid_amount)   AS total_outstanding
FROM claims c
WHERE c.total_charge_amount > c.total_paid_amount
  AND c.current_status_code NOT IN ('VOID', 'REJECTED', 'PAID')
GROUP BY 1;


-- ----------------------------------------------------------------------------
-- VIEW 11: vw_clean_claim_rate
-- ----------------------------------------------------------------------------
-- Clean claim rate by carrier - higher = fewer denials = healthier RCM.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_clean_claim_rate AS
SELECT
  c.carrier_id,
  COUNT(*)                                          AS total_claims,
  SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) AS clean_claims,
  ROUND(SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*), 2)                                AS clean_claim_rate_pct
FROM claims c
GROUP BY c.carrier_id;


-- ----------------------------------------------------------------------------
-- VIEW 12: vw_first_pass_resolution
-- ----------------------------------------------------------------------------
-- First-pass resolution rate (FPRR) = paid on first submission, no rework.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_first_pass_resolution AS
SELECT
  c.carrier_id,
  COUNT(*)                                                                           AS total_claims,
  SUM(CASE WHEN c.current_status_code = 'PAID' AND c.is_clean_claim = TRUE THEN 1
           ELSE 0 END)                                                               AS first_pass_resolved,
  ROUND(SUM(CASE WHEN c.current_status_code = 'PAID' AND c.is_clean_claim = TRUE THEN 1
                 ELSE 0 END) * 100.0 / COUNT(*), 2)                                  AS fpr_rate_pct
FROM claims c
GROUP BY c.carrier_id;


-- ----------------------------------------------------------------------------
-- VIEW 13: vw_monthly_collections
-- ----------------------------------------------------------------------------
-- Month-over-month collection trend for revenue dashboards.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_monthly_collections AS
SELECT
  DATE_FORMAT(pay.payment_date, '%Y-%m')              AS payment_month,
  COUNT(*)                                            AS payment_count,
  COUNT(DISTINCT pay.claim_id)                        AS claims_with_payment,
  SUM(pay.payment_amount)                             AS total_collected,
  AVG(pay.payment_amount)                             AS avg_payment,
  COUNT(DISTINCT pay.carrier_id)                      AS unique_carriers
FROM payments pay
WHERE pay.is_posted = TRUE
GROUP BY DATE_FORMAT(pay.payment_date, '%Y-%m')
ORDER BY payment_month DESC;


-- ----------------------------------------------------------------------------
-- VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected: total_views = 13
-- ----------------------------------------------------------------------------
SELECT 'Views created' AS status, COUNT(*) AS total_views
FROM information_schema.views
WHERE table_schema = 'HealthCare_THP'
  AND table_name LIKE 'vw_%';


-- ============================================================================
-- MYSQL SOURCE LAYER COMPLETE
--   12 tables (5 reference + 7 transactional)
--   13 views
--   25 total source objects
-- ============================================================================
