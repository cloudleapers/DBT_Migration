-- ============================================================================
-- FILE:        02_transactional_tables.sql
-- DATABASE:    MySQL (Aiven) - HealthCare_THP
-- PURPOSE:     Create 7 transactional claim tables and bulk-generate
--              ~209,000 rows of realistic synthetic claim activity.
-- ESTIMATED:   2-4 minutes (batch insert via numbers helper)
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   PHASE 1: Creates 7 transactional tables
--   PHASE 2: Creates a numbers_helper table (1 to 100,000 rows)
--   PHASE 3: Generates 30,000 claims via cross-join with numbers helper
--   PHASE 4: Generates 45,000 claim lines (~1.5 lines per claim)
--   PHASE 5: Generates 15,000 payments (~50% of claims have payments)
--   PHASE 6: Generates 14,000 adjustments
--   PHASE 7: Generates 12,000 remittance advice records
--   PHASE 8: Generates 87,000 status history records (avg 3 per claim)
--   PHASE 9: Generates 6,000 claim attachments
-- ============================================================================
-- WHY USE NUMBERS HELPER INSTEAD OF STORED PROCEDURES OR RECURSIVE CTE:
--   1. Stored procedures with DELIMITER syntax don't run in many MySQL
--      clients (Aiven web console, SQLTools VS Code, etc) - they fail
--      silently or with cryptic errors.
--   2. WITH RECURSIVE CTEs hit MySQL's default recursion limit of 1000
--      and require SET cte_max_recursion_depth in the SAME query block,
--      which most clients can't handle either.
--   3. The numbers helper pattern is portable across every MySQL client:
--      build a table of numbers once, then CROSS JOIN it for bulk inserts.
-- ============================================================================
-- DEPENDENCIES:
--   01_reference_tables.sql must run first.
-- ============================================================================

USE HealthCare_THP;


-- ----------------------------------------------------------------------------
-- PHASE 1A: CLAIMS TABLE
-- ----------------------------------------------------------------------------
-- The header for a claim. One row = one claim submitted to a payer.
-- patient_id, encounter_id, provider_id are external references to
-- PostgreSQL data (no FK because cross-database).
-- patient_mrn is denormalized for analyst convenience.
-- claim_type: P=Professional, I=Institutional, D=Dental, V=Vision, R=DME
-- filing_indicator: P=Primary, S=Secondary, T=Tertiary
-- ----------------------------------------------------------------------------
CREATE TABLE claims (
  claim_id              INT AUTO_INCREMENT PRIMARY KEY,
  claim_number          VARCHAR(30) NOT NULL UNIQUE,
  patient_id            INT NOT NULL,
  patient_mrn           VARCHAR(20),
  encounter_id          INT,
  encounter_number      VARCHAR(20),
  provider_id           INT NOT NULL,
  provider_npi          VARCHAR(15),
  facility_id           INT,
  carrier_id            INT NOT NULL,
  plan_id               INT NOT NULL,
  service_date          DATE NOT NULL,
  submission_date       DATE NOT NULL,
  total_charge_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_allowed_amount  DECIMAL(12,2) DEFAULT 0,
  total_paid_amount     DECIMAL(12,2) DEFAULT 0,
  patient_responsibility DECIMAL(12,2) DEFAULT 0,
  current_status_code   VARCHAR(20),
  primary_diagnosis     VARCHAR(10),
  claim_type            VARCHAR(20),
  is_clean_claim        BOOLEAN DEFAULT TRUE,
  filing_indicator      VARCHAR(10) DEFAULT 'P',
  created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (plan_id)             REFERENCES insurance_plans(plan_id),
  FOREIGN KEY (current_status_code) REFERENCES claim_status_codes(status_code),
  INDEX idx_claim_patient   (patient_id),
  INDEX idx_claim_carrier   (carrier_id),
  INDEX idx_claim_status    (current_status_code),
  INDEX idx_claim_dates     (service_date, submission_date)
);


-- ----------------------------------------------------------------------------
-- PHASE 1B: CLAIM_LINES TABLE
-- ----------------------------------------------------------------------------
-- Line items on a claim. One claim has 1 to many lines.
-- Each line is a single procedure with charge/allowed/paid amounts.
-- ----------------------------------------------------------------------------
CREATE TABLE claim_lines (
  claim_line_id      INT AUTO_INCREMENT PRIMARY KEY,
  claim_id           INT NOT NULL,
  line_number        INT NOT NULL,
  cpt_code           VARCHAR(15),
  modifier           VARCHAR(10),
  units              INT DEFAULT 1,
  unit_price         DECIMAL(10,2),
  charge_amount      DECIMAL(10,2),
  allowed_amount     DECIMAL(10,2),
  paid_amount        DECIMAL(10,2),
  diagnosis_pointer  VARCHAR(10),
  service_date       DATE,
  status_code        VARCHAR(20) DEFAULT 'PENDING',
  created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
  INDEX idx_line_claim (claim_id),
  INDEX idx_line_cpt   (cpt_code)
);


-- ----------------------------------------------------------------------------
-- PHASE 1C: PAYMENTS TABLE
-- ----------------------------------------------------------------------------
-- Payment events. is_posted = TRUE means the AR team has applied the
-- payment to the claim. days_to_post is computed downstream in dbt.
-- ----------------------------------------------------------------------------
CREATE TABLE payments (
  payment_id      INT AUTO_INCREMENT PRIMARY KEY,
  claim_id        INT NOT NULL,
  payment_number  VARCHAR(30),
  carrier_id      INT,
  payment_amount  DECIMAL(12,2) NOT NULL,
  payment_date    DATE NOT NULL,
  payment_method  VARCHAR(20),    -- EFT, Check, Credit Card, ACH
  check_number    VARCHAR(50),
  era_number      VARCHAR(50),
  is_posted       BOOLEAN DEFAULT FALSE,
  posted_date     DATE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
  INDEX idx_payment_claim   (claim_id),
  INDEX idx_payment_date    (payment_date)
);


-- ----------------------------------------------------------------------------
-- PHASE 1D: ADJUSTMENTS TABLE
-- ----------------------------------------------------------------------------
-- Adjustments to a claim or claim line. Each row references an
-- adjustment_code (CO-50, PR-1, etc) explaining the why.
-- ----------------------------------------------------------------------------
CREATE TABLE adjustments (
  adjustment_id     INT AUTO_INCREMENT PRIMARY KEY,
  claim_id          INT NOT NULL,
  claim_line_id     INT,
  adjustment_code   VARCHAR(20),
  adjustment_amount DECIMAL(10,2) NOT NULL,
  adjustment_date   DATE NOT NULL,
  notes             TEXT,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id)        REFERENCES claims(claim_id) ON DELETE CASCADE,
  FOREIGN KEY (adjustment_code) REFERENCES adjustment_codes(code),
  INDEX idx_adj_claim (claim_id)
);


-- ----------------------------------------------------------------------------
-- PHASE 1E: REMITTANCE_ADVICE TABLE
-- ----------------------------------------------------------------------------
-- ERA (Electronic Remittance Advice) and EOB summary records.
-- One per payment batch; each remittance can cover one or many claims.
-- ----------------------------------------------------------------------------
CREATE TABLE remittance_advice (
  remittance_id    INT AUTO_INCREMENT PRIMARY KEY,
  claim_id         INT NOT NULL,
  payer_id         VARCHAR(20),
  era_number       VARCHAR(50),
  check_number     VARCHAR(50),
  remittance_date  DATE,
  total_billed     DECIMAL(12,2),
  total_allowed    DECIMAL(12,2),
  total_paid       DECIMAL(12,2),
  total_adjustment DECIMAL(12,2),
  notes            TEXT,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
  INDEX idx_rem_claim (claim_id)
);


-- ----------------------------------------------------------------------------
-- PHASE 1F: CLAIM_STATUS_HISTORY TABLE
-- ----------------------------------------------------------------------------
-- Every status change a claim goes through. Used for cycle-time analytics.
-- ----------------------------------------------------------------------------
CREATE TABLE claim_status_history (
  history_id   INT AUTO_INCREMENT PRIMARY KEY,
  claim_id     INT NOT NULL,
  status_code  VARCHAR(20),
  status_date  DATE,
  status_time  TIME,
  changed_by   VARCHAR(50),
  notes        TEXT,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
  INDEX idx_hist_claim (claim_id, status_date)
);


-- ----------------------------------------------------------------------------
-- PHASE 1G: CLAIM_ATTACHMENTS TABLE
-- ----------------------------------------------------------------------------
-- Supporting docs attached to claims (medical records, X-rays, prior auth).
-- ----------------------------------------------------------------------------
CREATE TABLE claim_attachments (
  attachment_id   INT AUTO_INCREMENT PRIMARY KEY,
  claim_id        INT NOT NULL,
  attachment_type VARCHAR(50),
  file_name       VARCHAR(255),
  file_size_kb    INT,
  uploaded_date   DATE,
  uploaded_by     VARCHAR(100),
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
  INDEX idx_att_claim (claim_id)
);


-- ----------------------------------------------------------------------------
-- PHASE 2: NUMBERS HELPER TABLE (the alternative to stored procs / CTEs)
-- ----------------------------------------------------------------------------
-- This is a one-time helper table containing 1..100,000 sequential ints.
-- We use it as a counter source for bulk INSERTs via CROSS JOIN.
-- After population we keep it - costs almost nothing and useful elsewhere.
--
-- Build technique: cascade-join digit tables (each 0-9). 5 digits = 100K.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS numbers_helper;

CREATE TABLE numbers_helper (
  n INT PRIMARY KEY
);

-- Fast 100K row generation via cascade join of digit tables
INSERT INTO numbers_helper (n)
SELECT
  d1.d * 10000 + d2.d * 1000 + d3.d * 100 + d4.d * 10 + d5.d + 1 AS n
FROM
  (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1,
  (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2,
  (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3,
  (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4,
  (SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d5;

-- Verification: should return 100000
SELECT COUNT(*) AS numbers_helper_rows FROM numbers_helper;


-- ----------------------------------------------------------------------------
-- PHASE 3: GENERATE 30,000 CLAIMS
-- ----------------------------------------------------------------------------
-- Each row of numbers_helper (1..30000) becomes one claim.
-- Distributions:
--   - patient_id: spread across 5,000 patients (PG side has 5K patients)
--   - encounter_id: 1:1.5 ratio (some encounters get 2+ claims)
--   - provider_id: round-robin 50 providers
--   - carrier_id: weighted via modulo to favor commercial (1-7) over
--     government (8-9) and self-pay (10)
--   - plan_id: round-robin 25 plans
--   - service_date: spread across last 730 days
--   - submission_date: 0-15 days after service date
--   - charges: weighted toward common visit types
-- ----------------------------------------------------------------------------
INSERT INTO claims (
  claim_number, patient_id, patient_mrn, encounter_id, encounter_number,
  provider_id, provider_npi, facility_id, carrier_id, plan_id,
  service_date, submission_date,
  total_charge_amount, total_allowed_amount, total_paid_amount, patient_responsibility,
  current_status_code, primary_diagnosis, claim_type, is_clean_claim, filing_indicator
)
SELECT
  CONCAT('CLM', LPAD(n, 10, '0')),
  ((n - 1) % 5000) + 1                                       AS patient_id,
  CONCAT('MRN', LPAD(((n - 1) % 5000) + 1, 7, '0'))          AS patient_mrn,
  ((n - 1) % 20000) + 1                                      AS encounter_id,
  CONCAT('ENC', LPAD(((n - 1) % 20000) + 1, 8, '0'))         AS encounter_number,
  ((n - 1) % 50) + 1                                         AS provider_id,
  CONCAT('123456', LPAD(((n - 1) % 50) + 7890, 4, '0'))      AS provider_npi,
  ((n - 1) % 20) + 1                                         AS facility_id,
  -- carrier weighting: 70% commercial (1-7), 20% Medicare/Medicaid (8-9), 10% self-pay (10)
  CASE
    WHEN n % 10 = 0 THEN 10                                     -- self-pay
    WHEN n % 10 IN (8, 9) THEN ((n % 2) + 8)                    -- medicare or medicaid
    ELSE ((n % 7) + 1)                                          -- commercial
  END                                                        AS carrier_id,
  ((n - 1) % 25) + 1                                         AS plan_id,
  DATE_SUB(CURDATE(), INTERVAL ((n % 730) + 1) DAY)          AS service_date,
  DATE_SUB(CURDATE(), INTERVAL ((n % 730) - (n % 15)) DAY)   AS submission_date,
  -- charges follow the CPT distribution from PostgreSQL
  ELT(((n - 1) % 20) + 1,
      95.00, 130.00, 145.00, 175.00, 195.00,
      35.00, 28.00, 22.00, 25.00, 75.00,
      110.00, 850.00, 950.00, 18500.00, 4200.00,
      35.00, 45.00, 250.00, 650.00, 4500.00)                 AS total_charge_amount,
  -- allowed amount = ~75-90% of charge, varies by carrier
  ELT(((n - 1) % 20) + 1,
      80.00, 110.00, 122.00, 148.00, 165.00,
      30.00, 24.00, 18.00, 21.00, 64.00,
      94.00, 722.00, 808.00, 15725.00, 3570.00,
      30.00, 38.00, 213.00, 553.00, 3825.00)                 AS total_allowed_amount,
  -- paid amount: depends on status code (computed below)
  CASE
    WHEN n % 10 = 0 THEN 0                                  -- self-pay no payment yet
    WHEN n % 7 = 0 THEN 0                                   -- denied no payment
    ELSE
      ELT(((n - 1) % 20) + 1,
        72.00, 99.00, 110.00, 133.00, 148.50,
        27.00, 21.60, 16.20, 18.90, 57.60,
        84.60, 649.80, 727.20, 14152.50, 3213.00,
        27.00, 34.20, 191.70, 497.70, 3442.50)
  END                                                        AS total_paid_amount,
  -- patient responsibility: deductible and copay residue
  CASE
    WHEN n % 10 = 0 THEN
      ELT(((n - 1) % 20) + 1,
          95.00, 130.00, 145.00, 175.00, 195.00,
          35.00, 28.00, 22.00, 25.00, 75.00,
          110.00, 850.00, 950.00, 18500.00, 4200.00,
          35.00, 45.00, 250.00, 650.00, 4500.00)
    ELSE 25.00
  END                                                        AS patient_responsibility,
  -- status distribution roughly:
  --   60% PAID, 15% PARTIAL, 12% DENIED, 8% PENDING, 5% other
  CASE
    WHEN n % 100 < 60 THEN 'PAID'
    WHEN n % 100 < 75 THEN 'PARTIAL'
    WHEN n % 100 < 87 THEN 'DENIED'
    WHEN n % 100 < 95 THEN 'PENDING'
    WHEN n % 100 < 97 THEN 'IN_PROCESS'
    WHEN n % 100 < 99 THEN 'APPROVED'
    ELSE 'REJECTED'
  END                                                        AS current_status_code,
  ELT(((n - 1) % 20) + 1,
    'E11.9','I10','J45.909','M54.5','K21.9','F32.9','N18.9','I25.10','E78.5','J44.9',
    'M17.0','G43.909','R50.9','R10.9','J06.9','B34.9','S93.401','Z00.00','Z23','O80')  AS primary_diagnosis,
  ELT((n % 5) + 1, 'Professional','Professional','Professional','Institutional','Dental') AS claim_type,
  CASE WHEN n % 8 = 0 THEN FALSE ELSE TRUE END               AS is_clean_claim,
  CASE WHEN n % 20 = 0 THEN 'S' ELSE 'P' END                 AS filing_indicator
FROM numbers_helper
WHERE n <= 30000;


-- ----------------------------------------------------------------------------
-- PHASE 4: GENERATE CLAIM LINES (~45,000 rows)
-- ----------------------------------------------------------------------------
-- Strategy: every claim gets at least 1 line; every other claim gets 2.
-- Use UNION ALL to combine line 1 (all claims) + line 2 (every other claim).
-- ----------------------------------------------------------------------------
INSERT INTO claim_lines (
  claim_id, line_number, cpt_code, modifier, units, unit_price,
  charge_amount, allowed_amount, paid_amount, diagnosis_pointer, service_date, status_code
)
-- Line 1 for every claim
SELECT
  c.claim_id, 1,
  ELT(((c.claim_id - 1) % 20) + 1,
      '99213','99214','99203','99396','99397',
      '80053','80061','85025','83036','93000',
      '71046','72148','45378','27447','29881',
      '90471','90686','99281','99284','59400'),
  NULL, 1,
  c.total_charge_amount,
  c.total_charge_amount,
  c.total_allowed_amount,
  c.total_paid_amount,
  '1', c.service_date,
  c.current_status_code
FROM claims c

UNION ALL

-- Line 2 for every other claim (lab work add-on)
SELECT
  c.claim_id, 2,
  ELT(((c.claim_id) % 5) + 1, '80053','80061','85025','83036','93000'),
  NULL, 1,
  ELT(((c.claim_id) % 5) + 1, 35.00, 28.00, 22.00, 25.00, 75.00),
  ELT(((c.claim_id) % 5) + 1, 35.00, 28.00, 22.00, 25.00, 75.00),
  ELT(((c.claim_id) % 5) + 1, 30.00, 24.00, 18.00, 21.00, 64.00),
  ELT(((c.claim_id) % 5) + 1, 27.00, 21.60, 16.20, 18.90, 57.60),
  '1', c.service_date,
  c.current_status_code
FROM claims c
WHERE c.claim_id % 2 = 0;


-- ----------------------------------------------------------------------------
-- PHASE 5: GENERATE PAYMENTS (~15,000 rows - half the claims have payments)
-- ----------------------------------------------------------------------------
-- Filter: only PAID and PARTIAL claims get payment records.
-- Most are EFT (75%); rest are Check (25%).
-- 90% are posted; 10% pending posting.
-- ----------------------------------------------------------------------------
INSERT INTO payments (
  claim_id, payment_number, carrier_id, payment_amount,
  payment_date, payment_method, check_number, era_number,
  is_posted, posted_date
)
SELECT
  c.claim_id,
  CONCAT('PAY', LPAD(c.claim_id, 10, '0')),
  c.carrier_id,
  c.total_paid_amount,
  DATE_ADD(c.submission_date, INTERVAL ((c.claim_id % 30) + 5) DAY),
  CASE WHEN c.claim_id % 4 = 0 THEN 'Check' ELSE 'EFT' END,
  CASE WHEN c.claim_id % 4 = 0 THEN CONCAT('CHK', LPAD(c.claim_id, 8, '0')) ELSE NULL END,
  CASE WHEN c.claim_id % 4 != 0 THEN CONCAT('ERA', LPAD(c.claim_id, 8, '0')) ELSE NULL END,
  CASE WHEN c.claim_id % 10 = 0 THEN FALSE ELSE TRUE END,
  CASE
    WHEN c.claim_id % 10 = 0 THEN NULL
    ELSE DATE_ADD(c.submission_date, INTERVAL ((c.claim_id % 30) + 8) DAY)
  END
FROM claims c
WHERE c.current_status_code IN ('PAID', 'PARTIAL')
  AND c.total_paid_amount > 0;


-- ----------------------------------------------------------------------------
-- PHASE 6: GENERATE ADJUSTMENTS (~14,000 rows)
-- ----------------------------------------------------------------------------
-- Every claim gets at least one contractual adjustment (CO-45)
-- explaining the charge - allowed gap. PAID/PARTIAL only.
-- Plus extra adjustments for DENIED claims explaining why.
-- ----------------------------------------------------------------------------
INSERT INTO adjustments (claim_id, adjustment_code, adjustment_amount, adjustment_date, notes)
-- Contractual adjustment for paid/partial claims
SELECT
  c.claim_id,
  'CO-45',
  c.total_charge_amount - c.total_allowed_amount,
  DATE_ADD(c.submission_date, INTERVAL 7 DAY),
  'Contractual obligation per fee schedule'
FROM claims c
WHERE c.current_status_code IN ('PAID', 'PARTIAL')
  AND c.total_charge_amount > c.total_allowed_amount

UNION ALL

-- Denial-reason adjustment for denied claims
SELECT
  c.claim_id,
  ELT((c.claim_id % 6) + 1, 'CO-50', 'CO-167', 'CO-4', 'CO-11', 'CO-151', 'CO-16'),
  c.total_charge_amount,
  DATE_ADD(c.submission_date, INTERVAL 5 DAY),
  ELT((c.claim_id % 6) + 1,
      'Service deemed not medically necessary',
      'Diagnosis not covered for this procedure',
      'Procedure code inconsistent with modifier',
      'Diagnosis inconsistent with procedure',
      'Excessive units billed',
      'Required information missing')
FROM claims c
WHERE c.current_status_code = 'DENIED';


-- ----------------------------------------------------------------------------
-- PHASE 7: GENERATE REMITTANCE ADVICE (~12,000 rows)
-- ----------------------------------------------------------------------------
-- One per posted claim with payment.
-- ----------------------------------------------------------------------------
INSERT INTO remittance_advice (
  claim_id, payer_id, era_number, check_number,
  remittance_date, total_billed, total_allowed, total_paid, total_adjustment, notes
)
SELECT
  c.claim_id,
  CASE c.carrier_id
    WHEN 1  THEN 'BCBS001'
    WHEN 2  THEN 'AETNA001'
    WHEN 3  THEN 'UHC001'
    WHEN 4  THEN 'CIGNA001'
    WHEN 5  THEN 'HUMANA001'
    WHEN 6  THEN 'KAISER001'
    WHEN 7  THEN 'ANTHEM001'
    WHEN 8  THEN 'MEDIC001'
    WHEN 9  THEN 'MEDCD001'
    ELSE 'SELF001'
  END,
  CONCAT('ERA', LPAD(c.claim_id, 8, '0')),
  CASE WHEN c.claim_id % 4 = 0 THEN CONCAT('CHK', LPAD(c.claim_id, 8, '0')) ELSE NULL END,
  DATE_ADD(c.submission_date, INTERVAL 10 DAY),
  c.total_charge_amount,
  c.total_allowed_amount,
  c.total_paid_amount,
  c.total_charge_amount - c.total_paid_amount,
  'Standard remittance'
FROM claims c
WHERE c.current_status_code IN ('PAID', 'PARTIAL')
  AND c.total_paid_amount > 0;


-- ----------------------------------------------------------------------------
-- PHASE 8: GENERATE STATUS HISTORY (~87,000 rows)
-- ----------------------------------------------------------------------------
-- Each claim averages 3 status changes (SUBMITTED -> PENDING/IN_PROCESS ->
-- terminal). We generate 3 history records per claim.
-- ----------------------------------------------------------------------------
INSERT INTO claim_status_history (claim_id, status_code, status_date, status_time, changed_by, notes)
-- Status 1: SUBMITTED
SELECT
  c.claim_id, 'SUBMITTED', c.submission_date, '08:00:00', 'system', 'Initial submission'
FROM claims c

UNION ALL

-- Status 2: IN_PROCESS
SELECT
  c.claim_id, 'IN_PROCESS',
  DATE_ADD(c.submission_date, INTERVAL 2 DAY), '14:30:00',
  CONCAT('payer_', c.carrier_id), 'Adjudication started'
FROM claims c

UNION ALL

-- Status 3: terminal
SELECT
  c.claim_id, c.current_status_code,
  DATE_ADD(c.submission_date, INTERVAL ((c.claim_id % 14) + 5) DAY), '16:00:00',
  CONCAT('payer_', c.carrier_id),
  CASE c.current_status_code
    WHEN 'PAID' THEN 'Claim paid in full'
    WHEN 'PARTIAL' THEN 'Partial payment issued'
    WHEN 'DENIED' THEN 'Claim denied'
    WHEN 'REJECTED' THEN 'Claim rejected'
    WHEN 'PENDING' THEN 'Awaiting additional information'
    ELSE 'Status changed'
  END
FROM claims c;


-- ----------------------------------------------------------------------------
-- PHASE 9: GENERATE ATTACHMENTS (~6,000 rows)
-- ----------------------------------------------------------------------------
-- Roughly every 5th claim has an attachment.
-- ----------------------------------------------------------------------------
INSERT INTO claim_attachments (
  claim_id, attachment_type, file_name, file_size_kb,
  uploaded_date, uploaded_by, notes
)
SELECT
  c.claim_id,
  ELT((c.claim_id % 5) + 1, 'Medical Records', 'X-ray Image', 'Lab Report', 'Operative Report', 'Prior Authorization'),
  CONCAT('claim_', c.claim_id, '_attachment.pdf'),
  ((c.claim_id % 9000) + 100),
  DATE_ADD(c.submission_date, INTERVAL 1 DAY),
  CONCAT('user_', (c.claim_id % 10) + 1),
  'Supporting documentation'
FROM claims c
WHERE c.claim_id % 5 = 0;


-- ----------------------------------------------------------------------------
-- PHASE 10: VERIFICATION
-- ----------------------------------------------------------------------------
SELECT 'Transactional tables loaded' AS status,
       (SELECT COUNT(*) FROM claims)               AS claims,
       (SELECT COUNT(*) FROM claim_lines)          AS claim_lines,
       (SELECT COUNT(*) FROM payments)             AS payments,
       (SELECT COUNT(*) FROM adjustments)          AS adjustments,
       (SELECT COUNT(*) FROM remittance_advice)    AS remittance,
       (SELECT COUNT(*) FROM claim_status_history) AS status_history,
       (SELECT COUNT(*) FROM claim_attachments)    AS attachments;


-- ============================================================================
-- NEXT FILE:  03_views.sql
-- ============================================================================
