-- ============================================================================
-- FILE:        01_reference_tables.sql
-- DATABASE:    MySQL (Aiven) - HealthCare_THP database
-- PURPOSE:     Create reference/lookup tables for the claims domain.
-- RUNNER:      Aiven console SQL editor, MySQL Workbench, or VS Code
--              SQLTools with MySQL driver
-- ESTIMATED:   < 10 seconds
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   PHASE 1: Drops every project table (idempotent reset)
--   PHASE 2: Creates 5 reference tables:
--            - payer_types         (Commercial, Medicare, Medicaid, etc)
--            - insurance_plans     (specific plans per carrier)
--            - billing_codes       (CPT and HCPCS billing codes)
--            - claim_status_codes  (claim lifecycle states)
--            - adjustment_codes    (denial/adjustment reason codes)
--   PHASE 3: Seeds reference data (~90 rows total)
-- ============================================================================
-- IMPORTANT NOTES (lessons learned during initial development):
--   - Database name HealthCare_THP is case-sensitive in Aiven MySQL.
--     Always use `USE HealthCare_THP;` exactly with this casing.
--   - Avoid problematic strings in seed data: certain words like 'TRICARE'
--     in all-caps next to single quotes can confuse MySQL parsers in
--     some clients. Using sentence case ('Tricare') is safer.
--   - Em-dashes and other Unicode characters can break parsing in some
--     MySQL clients. Use plain ASCII hyphens.
-- ============================================================================
-- DEPENDENCIES:
--   None - this is the first MySQL file. Database HealthCare_THP must exist.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1: SET DATABASE CONTEXT (case-sensitive!)
-- ----------------------------------------------------------------------------
USE HealthCare_THP;


-- ----------------------------------------------------------------------------
-- PHASE 2: CLEAN SLATE (drop in dependency-safe order)
-- ----------------------------------------------------------------------------
-- Children before parents. CASCADE not supported in MySQL DROP TABLE
-- so we must drop in the correct order manually.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS claim_attachments;
DROP TABLE IF EXISTS claim_status_history;
DROP TABLE IF EXISTS adjustments;
DROP TABLE IF EXISTS remittance_advice;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS claim_lines;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS adjustment_codes;
DROP TABLE IF EXISTS claim_status_codes;
DROP TABLE IF EXISTS billing_codes;
DROP TABLE IF EXISTS insurance_plans;
DROP TABLE IF EXISTS payer_types;


-- ----------------------------------------------------------------------------
-- PHASE 3A: PAYER_TYPES TABLE
-- ----------------------------------------------------------------------------
-- High-level taxonomy of payers. Used to roll up insurance plans by
-- segment (Government vs Commercial vs Patient).
-- ----------------------------------------------------------------------------
CREATE TABLE payer_types (
  payer_type_id INT AUTO_INCREMENT PRIMARY KEY,
  type_code     VARCHAR(20) NOT NULL UNIQUE,
  type_name     VARCHAR(50) NOT NULL,
  description   TEXT,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 3B: INSURANCE_PLANS TABLE
-- ----------------------------------------------------------------------------
-- Specific insurance plans (e.g., "BCBS PPO Gold"). Each ties to a
-- carrier and payer type. Includes deductible/copay info for analytics.
-- carrier_id intentionally not a FK because in this training project
-- carriers live in PostgreSQL, not MySQL.
-- ----------------------------------------------------------------------------
CREATE TABLE insurance_plans (
  plan_id           INT AUTO_INCREMENT PRIMARY KEY,
  plan_code         VARCHAR(30) NOT NULL UNIQUE,
  plan_name         VARCHAR(100) NOT NULL,
  carrier_id        INT NOT NULL,
  payer_type_id     INT NOT NULL,
  plan_type         VARCHAR(20),
  deductible_amount DECIMAL(10,2),
  copay_amount      DECIMAL(10,2),
  out_of_pocket_max DECIMAL(10,2),
  is_active         BOOLEAN DEFAULT TRUE,
  effective_date    DATE,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (payer_type_id) REFERENCES payer_types(payer_type_id)
);


-- ----------------------------------------------------------------------------
-- PHASE 3C: BILLING_CODES TABLE
-- ----------------------------------------------------------------------------
-- CPT and HCPCS codes used in claim line items. Mirrors PostgreSQL's
-- cpt_codes table because both source systems track procedures
-- independently (typical in real organizations).
-- ----------------------------------------------------------------------------
CREATE TABLE billing_codes (
  billing_code_id INT AUTO_INCREMENT PRIMARY KEY,
  code            VARCHAR(15) NOT NULL UNIQUE,
  description     VARCHAR(255),
  code_type       VARCHAR(20),    -- 'CPT' or 'HCPCS'
  base_charge     DECIMAL(10,2),
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 3D: CLAIM_STATUS_CODES TABLE
-- ----------------------------------------------------------------------------
-- The lifecycle states a claim can be in.
-- is_terminal flag indicates final states (won't change again).
-- ----------------------------------------------------------------------------
CREATE TABLE claim_status_codes (
  status_code_id INT AUTO_INCREMENT PRIMARY KEY,
  status_code    VARCHAR(20) NOT NULL UNIQUE,
  status_name    VARCHAR(50) NOT NULL,
  description    TEXT,
  is_terminal    BOOLEAN DEFAULT FALSE,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 3E: ADJUSTMENT_CODES TABLE
-- ----------------------------------------------------------------------------
-- Reason codes for claim adjustments. Standard CARC (Claim Adjustment
-- Reason Codes) prefixed with category:
--   CO = Contractual Obligation
--   PR = Patient Responsibility
--   PI = Payer Initiated
--   OA = Other Adjustment
--   CR = Correction or Reversal
-- is_denial flag separates true denials from contractual write-offs.
-- ----------------------------------------------------------------------------
CREATE TABLE adjustment_codes (
  adjustment_code_id INT AUTO_INCREMENT PRIMARY KEY,
  code               VARCHAR(20) NOT NULL UNIQUE,
  description        VARCHAR(255),
  category           VARCHAR(50),
  is_denial          BOOLEAN DEFAULT FALSE,
  created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 4A: SEED PAYER_TYPES (8 rows)
-- ----------------------------------------------------------------------------
-- Note: 'Tricare' uses sentence case (not 'TRICARE') to avoid MySQL
-- parser quirks observed in some clients during development.
-- ----------------------------------------------------------------------------
INSERT INTO payer_types (type_code, type_name, description) VALUES
('COMM',     'Commercial',          'Private insurance plans'),
('MEDCARE',  'Medicare',            'Federal program for 65 and older'),
('MEDCAID',  'Medicaid',            'State federal program for low income'),
('SELFPAY',  'Self-Pay',            'Patient pays out of pocket'),
('WORK',     'Workers Comp',        'Workplace injury coverage'),
('AUTO',     'Auto Insurance',      'Auto accident coverage'),
('TRIC',     'Tricare',             'Military and dependents'),
('VAB',      'VA Benefits',         'Veterans Affairs benefits');


-- ----------------------------------------------------------------------------
-- PHASE 4B: SEED INSURANCE_PLANS (25 rows)
-- ----------------------------------------------------------------------------
-- 25 plans across major carriers + government + special types.
-- Plan types: PPO, HMO, EPO, HSA, GOV (government), RX (Medicare Part D),
-- NONE (self-pay).
-- carrier_id 1-7 are the commercial carriers from PostgreSQL,
-- 8 = Medicare, 9 = Medicaid, 10 = Self-Pay (matches insurance_carriers).
-- ----------------------------------------------------------------------------
INSERT INTO insurance_plans (plan_code, plan_name, carrier_id, payer_type_id, plan_type, deductible_amount, copay_amount, out_of_pocket_max, effective_date) VALUES
('BCBS-PPO-GOLD',      'BCBS PPO Gold',                1, 1, 'PPO', 1500.00, 30.00, 6000.00,  '2020-01-01'),
('BCBS-HMO-SILVER',    'BCBS HMO Silver',              1, 1, 'HMO', 2500.00, 25.00, 8000.00,  '2020-01-01'),
('AETNA-PPO-PLAT',     'Aetna PPO Platinum',           2, 1, 'PPO', 1000.00, 20.00, 5000.00,  '2020-01-01'),
('AETNA-HSA',          'Aetna HSA Eligible',           2, 1, 'HSA', 3500.00, 0.00,  7000.00,  '2020-01-01'),
('UHC-CHOICE-PLUS',    'UHC Choice Plus',              3, 1, 'PPO', 2000.00, 35.00, 7500.00,  '2020-01-01'),
('UHC-NAVIGATE',       'UHC Navigate',                 3, 1, 'EPO', 2500.00, 30.00, 6500.00,  '2020-01-01'),
('CIGNA-OPEN-ACCESS',  'Cigna Open Access Plus',       4, 1, 'PPO', 1750.00, 25.00, 6500.00,  '2020-01-01'),
('CIGNA-LOCAL',        'Cigna LocalPlus',              4, 1, 'EPO', 2000.00, 30.00, 7000.00,  '2020-01-01'),
('HUMANA-GOLD-PLUS',   'Humana Gold Plus',             5, 1, 'HMO', 1500.00, 25.00, 6000.00,  '2020-01-01'),
('HUMANA-CHOICE-PPO',  'Humana ChoiceCare PPO',        5, 1, 'PPO', 2500.00, 35.00, 7500.00,  '2020-01-01'),
('KAISER-HMO-CA',      'Kaiser CA HMO',                6, 1, 'HMO', 0.00,    20.00, 5000.00,  '2020-01-01'),
('ANTHEM-BLUE-CARE',   'Anthem Blue Care PPO',         7, 1, 'PPO', 2000.00, 30.00, 7000.00,  '2020-01-01'),
('MEDICARE-PARTAB',    'Medicare Part A and B',        8, 2, 'GOV', 1632.00, 0.00,  0.00,     '2010-01-01'),
('MEDICARE-PARTC-HMO', 'Medicare Advantage HMO',       8, 2, 'HMO', 0.00,    15.00, 8300.00,  '2015-01-01'),
('MEDICARE-PARTC-PPO', 'Medicare Advantage PPO',       8, 2, 'PPO', 250.00,  20.00, 8300.00,  '2015-01-01'),
('MEDICARE-PARTD',     'Medicare Part D Drugs',        8, 2, 'RX',  545.00,  0.00,  8000.00,  '2015-01-01'),
('MEDICAID-CA-MEDI',   'California Medi-Cal',          9, 3, 'GOV', 0.00,    0.00,  0.00,     '2010-01-01'),
('MEDICAID-TX-STAR',   'Texas STAR Medicaid',          9, 3, 'GOV', 0.00,    0.00,  0.00,     '2010-01-01'),
('MEDICAID-NY-MGD',    'NY Medicaid Managed Care',     9, 3, 'HMO', 0.00,    0.00,  0.00,     '2010-01-01'),
('MEDICAID-FL-AHCA',   'Florida Medicaid AHCA',        9, 3, 'GOV', 0.00,    0.00,  0.00,     '2010-01-01'),
('SELFPAY-STD',        'Self-Pay Standard',           10, 4, 'NONE', 0.00,   0.00,  0.00,     '2010-01-01'),
('TRICARE-PRIME',      'Tricare Prime',                1, 7, 'HMO', 0.00,    20.00, 3500.00,  '2018-01-01'),
('VA-COMM-CARE',       'VA Community Care',            1, 8, 'GOV', 0.00,    0.00,  0.00,     '2018-01-01'),
('WORKERS-COMP-STD',   'Workers Compensation Std',     1, 5, 'GOV', 0.00,    0.00,  0.00,     '2010-01-01'),
('AUTO-PIP-STD',       'Auto PIP',                     1, 6, 'GOV', 0.00,    0.00,  0.00,     '2010-01-01');


-- ----------------------------------------------------------------------------
-- PHASE 4C: SEED BILLING_CODES (25 rows)
-- ----------------------------------------------------------------------------
-- 20 CPT codes (mirror PostgreSQL cpt_codes) + 5 HCPCS codes (DME etc).
-- ----------------------------------------------------------------------------
INSERT INTO billing_codes (code, description, code_type, base_charge) VALUES
('99213', 'Office visit established low complexity',     'CPT',    95.00),
('99214', 'Office visit established moderate complexity','CPT',   130.00),
('99203', 'Office visit new patient moderate',           'CPT',   145.00),
('99396', 'Preventive exam age 40-64',                   'CPT',   175.00),
('99397', 'Preventive exam age 65 plus',                 'CPT',   195.00),
('80053', 'Comprehensive metabolic panel',               'CPT',    35.00),
('80061', 'Lipid panel',                                 'CPT',    28.00),
('85025', 'CBC with differential',                       'CPT',    22.00),
('83036', 'Hemoglobin A1c',                              'CPT',    25.00),
('93000', 'EKG complete',                                'CPT',    75.00),
('71046', 'Chest X-ray two views',                       'CPT',   110.00),
('72148', 'MRI lumbar spine',                            'CPT',   850.00),
('45378', 'Diagnostic colonoscopy',                      'CPT',   950.00),
('27447', 'Total knee arthroplasty',                     'CPT', 18500.00),
('29881', 'Knee arthroscopy meniscectomy',               'CPT',  4200.00),
('90471', 'Immunization administration',                 'CPT',    35.00),
('90686', 'Influenza vaccine quadrivalent',              'CPT',    45.00),
('99281', 'Emergency dept visit minor',                  'CPT',   250.00),
('99284', 'Emergency dept visit high complexity',        'CPT',   650.00),
('59400', 'Routine OB care vaginal delivery',            'CPT',  4500.00),
('A4253', 'Blood glucose test strips 50 count',          'HCPCS',  25.00),
('E0114', 'Crutches underarm pair',                      'HCPCS',  45.00),
('J3490', 'Unclassified drugs',                          'HCPCS',  50.00),
('S9123', 'Nursing home visit per hour',                 'HCPCS',  65.00),
('Q0091', 'Screening pap smear',                         'HCPCS',  40.00);


-- ----------------------------------------------------------------------------
-- PHASE 4D: SEED CLAIM_STATUS_CODES (12 rows)
-- ----------------------------------------------------------------------------
-- The full claim lifecycle from submission to terminal state.
-- Terminal states: PAID, PARTIAL, DENIED, REJECTED, REVERSED, VOID
-- Non-terminal: SUBMITTED, PENDING, IN_PROCESS, APPROVED, APPEALED, FORWARDED
-- ----------------------------------------------------------------------------
INSERT INTO claim_status_codes (status_code, status_name, description, is_terminal) VALUES
('SUBMITTED',  'Submitted',         'Claim sent to payer',                            FALSE),
('PENDING',    'Pending Review',    'Under payer review',                             FALSE),
('IN_PROCESS', 'In Process',        'Being adjudicated',                              FALSE),
('APPROVED',   'Approved',          'Approved for payment',                           FALSE),
('PAID',       'Paid',              'Payment issued',                                 TRUE),
('PARTIAL',    'Partially Paid',    'Partial payment balance owed',                   TRUE),
('DENIED',     'Denied',            'Claim denied by payer',                          TRUE),
('REJECTED',   'Rejected',          'Rejected before processing submission errors',   TRUE),
('APPEALED',   'Under Appeal',      'Appeal in progress',                             FALSE),
('REVERSED',   'Reversed',          'Payment reversed or recouped',                   TRUE),
('VOID',       'Voided',            'Claim voided by provider',                       TRUE),
('FORWARDED',  'Forwarded',         'Forwarded to secondary payer',                   FALSE);


-- ----------------------------------------------------------------------------
-- PHASE 4E: SEED ADJUSTMENT_CODES (20 rows)
-- ----------------------------------------------------------------------------
-- Standard CARC codes used by US payers. is_denial separates patient
-- responsibility (NOT denials) from true denials needing follow-up.
-- ----------------------------------------------------------------------------
INSERT INTO adjustment_codes (code, description, category, is_denial) VALUES
('CO-1',   'Deductible amount',                               'Patient Responsibility',  FALSE),
('CO-2',   'Coinsurance amount',                              'Patient Responsibility',  FALSE),
('CO-3',   'Copayment amount',                                'Patient Responsibility',  FALSE),
('CO-4',   'Procedure code inconsistent with modifier',       'Coding Issue',            TRUE),
('CO-11',  'Diagnosis inconsistent with procedure',           'Coding Issue',            TRUE),
('CO-16',  'Claim lacks information needed',                  'Information Missing',     TRUE),
('CO-18',  'Duplicate claim or service',                      'Duplicate',               TRUE),
('CO-22',  'Care may be covered by another payer',            'Coordination of Benefits',TRUE),
('CO-29',  'Time limit for filing has expired',               'Filing Limit',            TRUE),
('CO-45',  'Charges exceed contracted fee',                   'Contractual',             FALSE),
('CO-50',  'Non-covered services not deemed necessity',       'Medical Necessity',       TRUE),
('CO-96',  'Non-covered charges',                             'Non-Covered',             TRUE),
('CO-97',  'Benefit included in another service',             'Bundling',                TRUE),
('CO-109', 'Claim not covered by this payer',                 'Wrong Payer',             TRUE),
('CO-151', 'Excessive units billed',                          'Coding Issue',            TRUE),
('CO-167', 'Diagnosis not covered',                           'Medical Necessity',       TRUE),
('OA-23',  'Impact of prior payer adjudication',              'Coordination of Benefits',FALSE),
('PI-204', 'Service not covered under patient plan',          'Plan Coverage',           TRUE),
('CR-1',   'Reversal of previous payment',                    'Reversal',                FALSE),
('PR-1',   'Patient deductible',                              'Patient Responsibility',  FALSE);


-- ----------------------------------------------------------------------------
-- PHASE 5: VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected output:
--   payer_types: 8   insurance_plans: 25   billing_codes: 25
--   status_codes: 12   adjustment_codes: 20
-- ----------------------------------------------------------------------------
SELECT 'Reference tables created' AS status,
       (SELECT COUNT(*) FROM payer_types)         AS payer_types,
       (SELECT COUNT(*) FROM insurance_plans)     AS insurance_plans,
       (SELECT COUNT(*) FROM billing_codes)       AS billing_codes,
       (SELECT COUNT(*) FROM claim_status_codes)  AS status_codes,
       (SELECT COUNT(*) FROM adjustment_codes)    AS adjustment_codes;


-- ============================================================================
-- NEXT FILE:  02_transactional_tables.sql
-- ============================================================================
