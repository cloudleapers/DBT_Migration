-- ============================================================================
-- FILE:        01_lookups.sql
-- DATABASE:    PostgreSQL (Supabase) - public schema
-- PURPOSE:     Create reference / lookup tables and seed them with codes.
-- RUNNER:      Supabase SQL Editor, pgAdmin, or any psql client
-- ESTIMATED:   < 10 seconds
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   PHASE 1: Drops every project table + dependent objects (idempotent reset)
--   PHASE 2: Creates 5 lookup tables:
--            - icd10_codes      (diagnostic codes)
--            - cpt_codes        (procedure codes)
--            - specialty_types  (medical specialties)
--            - states           (US states + region)
--            - facility_types   (hospital/clinic categories)
--   PHASE 3: Seeds reference data (~80 rows total)
--   PHASE 4: Verification query
-- ============================================================================
-- TABLES CREATED IN THIS FILE:
--   icd10_codes, cpt_codes, specialty_types, states, facility_types
-- ============================================================================
-- DEPENDENCIES:
--   None - this is the first file to run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1: CLEAN SLATE (drops in dependency-safe order)
-- ----------------------------------------------------------------------------
-- CASCADE removes any FK references automatically. This makes the script
-- safe to re-run from scratch without worrying about constraint errors.
-- The drop order is reverse of creation: child tables before parents.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS encounter_procedures   CASCADE;
DROP TABLE IF EXISTS encounter_diagnoses    CASCADE;
DROP TABLE IF EXISTS prescriptions          CASCADE;
DROP TABLE IF EXISTS lab_results            CASCADE;
DROP TABLE IF EXISTS lab_orders             CASCADE;
DROP TABLE IF EXISTS vitals                 CASCADE;
DROP TABLE IF EXISTS allergies              CASCADE;
DROP TABLE IF EXISTS encounters             CASCADE;
DROP TABLE IF EXISTS patients               CASCADE;
DROP TABLE IF EXISTS providers              CASCADE;
DROP TABLE IF EXISTS facilities             CASCADE;
DROP TABLE IF EXISTS insurance_carriers     CASCADE;
DROP TABLE IF EXISTS employees              CASCADE;
DROP TABLE IF EXISTS icd10_codes            CASCADE;
DROP TABLE IF EXISTS cpt_codes              CASCADE;
DROP TABLE IF EXISTS specialty_types        CASCADE;
DROP TABLE IF EXISTS states                 CASCADE;
DROP TABLE IF EXISTS facility_types         CASCADE;


-- ----------------------------------------------------------------------------
-- PHASE 2A: ICD-10 CODES (Disease classification)
-- ----------------------------------------------------------------------------
-- Standard international diagnostic coding system.
-- Loaded with ~20 common diagnoses spanning chronic and acute conditions.
-- The is_chronic flag drives downstream chronic-patient analytics.
-- ----------------------------------------------------------------------------
CREATE TABLE icd10_codes (
  code        VARCHAR(10) PRIMARY KEY,
  description TEXT NOT NULL,
  category    VARCHAR(50),
  is_chronic  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 2B: CPT CODES (Procedure classification)
-- ----------------------------------------------------------------------------
-- Current Procedural Terminology - billing codes for medical services.
-- base_cost is a typical Medicare reimbursement reference; actual claim
-- amounts vary by payer.
-- ----------------------------------------------------------------------------
CREATE TABLE cpt_codes (
  code        VARCHAR(10) PRIMARY KEY,
  description TEXT NOT NULL,
  category    VARCHAR(50),
  base_cost   NUMERIC(10,2),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 2C: SPECIALTY TYPES
-- ----------------------------------------------------------------------------
-- Medical specialty taxonomy for providers.
-- ----------------------------------------------------------------------------
CREATE TABLE specialty_types (
  specialty_id   SERIAL PRIMARY KEY,
  specialty_name VARCHAR(100) NOT NULL UNIQUE,
  description    TEXT
);


-- ----------------------------------------------------------------------------
-- PHASE 2D: STATES
-- ----------------------------------------------------------------------------
-- US states with regional grouping. Used for geographic analytics in marts.
-- ----------------------------------------------------------------------------
CREATE TABLE states (
  state_code  CHAR(2) PRIMARY KEY,
  state_name  VARCHAR(50) NOT NULL,
  region      VARCHAR(20)
);


-- ----------------------------------------------------------------------------
-- PHASE 2E: FACILITY TYPES
-- ----------------------------------------------------------------------------
-- Categorizes facilities (hospital, clinic, urgent care, etc).
-- ----------------------------------------------------------------------------
CREATE TABLE facility_types (
  type_id     SERIAL PRIMARY KEY,
  type_name   VARCHAR(50) NOT NULL UNIQUE,
  description TEXT
);


-- ----------------------------------------------------------------------------
-- PHASE 3A: SEED ICD-10 CODES (20 rows)
-- ----------------------------------------------------------------------------
-- Mix of chronic (E11.9, I10, J45.909, etc) and acute conditions.
-- Categories drive risk-tier classification in dim_diagnosis.
-- ----------------------------------------------------------------------------
INSERT INTO icd10_codes (code, description, category, is_chronic) VALUES
('E11.9',  'Type 2 diabetes mellitus without complications',     'Endocrine',       TRUE),
('I10',    'Essential (primary) hypertension',                   'Cardiovascular',  TRUE),
('J45.909','Unspecified asthma, uncomplicated',                  'Respiratory',     TRUE),
('M54.5',  'Low back pain',                                      'Musculoskeletal', FALSE),
('K21.9',  'Gastro-esophageal reflux disease',                   'Digestive',       TRUE),
('F32.9',  'Major depressive disorder, single episode',          'Mental',          TRUE),
('N18.9',  'Chronic kidney disease, unspecified',                'Renal',           TRUE),
('I25.10', 'Atherosclerotic heart disease',                      'Cardiovascular',  TRUE),
('E78.5',  'Hyperlipidemia, unspecified',                        'Endocrine',       TRUE),
('J44.9',  'Chronic obstructive pulmonary disease',              'Respiratory',     TRUE),
('M17.0',  'Bilateral primary osteoarthritis of knee',           'Musculoskeletal', TRUE),
('G43.909','Migraine, unspecified',                              'Neurological',    FALSE),
('R50.9',  'Fever, unspecified',                                 'Symptoms',        FALSE),
('R10.9',  'Unspecified abdominal pain',                         'Symptoms',        FALSE),
('J06.9',  'Acute upper respiratory infection',                  'Respiratory',     FALSE),
('B34.9',  'Viral infection, unspecified',                       'Infectious',      FALSE),
('S93.401','Sprain of unspecified ligament of right ankle',      'Injury',          FALSE),
('Z00.00', 'General adult medical examination',                  'Wellness',        FALSE),
('Z23',    'Encounter for immunization',                         'Wellness',        FALSE),
('O80',    'Encounter for full-term uncomplicated delivery',     'Pregnancy',       FALSE);


-- ----------------------------------------------------------------------------
-- PHASE 3B: SEED CPT CODES (20 rows)
-- ----------------------------------------------------------------------------
-- Mix of E&M (office visits), Lab, Radiology, Surgery codes with
-- representative pricing.
-- ----------------------------------------------------------------------------
INSERT INTO cpt_codes (code, description, category, base_cost) VALUES
('99213', 'Office visit, established patient, low complexity',      'E&M',          95.00),
('99214', 'Office visit, established patient, moderate complexity', 'E&M',         130.00),
('99203', 'Office visit, new patient, moderate complexity',         'E&M',         145.00),
('99396', 'Periodic preventive exam, age 40-64',                    'Preventive',  175.00),
('99397', 'Periodic preventive exam, age 65+',                      'Preventive',  195.00),
('80053', 'Comprehensive metabolic panel',                          'Lab',          35.00),
('80061', 'Lipid panel',                                            'Lab',          28.00),
('85025', 'Complete blood count with differential',                 'Lab',          22.00),
('83036', 'Hemoglobin A1c',                                         'Lab',          25.00),
('93000', 'Electrocardiogram, complete',                            'Cardiology',   75.00),
('71046', 'Chest X-ray, two views',                                 'Radiology',   110.00),
('72148', 'MRI lumbar spine without contrast',                      'Radiology',   850.00),
('45378', 'Diagnostic colonoscopy',                                 'GI Procedure',950.00),
('27447', 'Total knee arthroplasty',                                'Surgery',   18500.00),
('29881', 'Knee arthroscopy with meniscectomy',                     'Surgery',    4200.00),
('90471', 'Immunization administration, single',                    'Immunization', 35.00),
('90686', 'Influenza vaccine, quadrivalent',                        'Immunization', 45.00),
('99281', 'Emergency dept visit, minor',                            'ED',          250.00),
('99284', 'Emergency dept visit, high complexity',                  'ED',          650.00),
('59400', 'Routine obstetric care, vaginal delivery',               'Obstetrics', 4500.00);


-- ----------------------------------------------------------------------------
-- PHASE 3C: SEED SPECIALTY TYPES (15 rows)
-- ----------------------------------------------------------------------------
INSERT INTO specialty_types (specialty_name, description) VALUES
('Family Medicine',     'Primary care for all ages'),
('Internal Medicine',   'Adult primary care'),
('Pediatrics',          'Children'),
('Cardiology',          'Heart and vessels'),
('Endocrinology',       'Hormones and diabetes'),
('Gastroenterology',    'Digestive'),
('Nephrology',          'Kidney'),
('Orthopedics',         'Musculoskeletal'),
('Neurology',           'Brain and nerves'),
('Psychiatry',          'Mental health'),
('OB/GYN',              'Womens health'),
('Emergency Medicine',  'ER care'),
('Radiology',           'Imaging'),
('Anesthesiology',      'Anesthesia'),
('General Surgery',     'Surgical procedures');


-- ----------------------------------------------------------------------------
-- PHASE 3D: SEED STATES (20 rows of major US states + region)
-- ----------------------------------------------------------------------------
INSERT INTO states (state_code, state_name, region) VALUES
('CA','California',    'West'),     ('NY','New York',      'Northeast'),
('TX','Texas',         'South'),    ('FL','Florida',       'South'),
('IL','Illinois',      'Midwest'),  ('PA','Pennsylvania',  'Northeast'),
('OH','Ohio',          'Midwest'),  ('GA','Georgia',       'South'),
('NC','North Carolina','South'),    ('MI','Michigan',      'Midwest'),
('NJ','New Jersey',    'Northeast'),('VA','Virginia',      'South'),
('WA','Washington',    'West'),     ('AZ','Arizona',       'West'),
('MA','Massachusetts', 'Northeast'),('TN','Tennessee',     'South'),
('IN','Indiana',       'Midwest'),  ('MO','Missouri',      'Midwest'),
('MD','Maryland',      'South'),    ('WI','Wisconsin',     'Midwest');


-- ----------------------------------------------------------------------------
-- PHASE 3E: SEED FACILITY TYPES (7 rows)
-- ----------------------------------------------------------------------------
INSERT INTO facility_types (type_name, description) VALUES
('Hospital',          'Inpatient + outpatient'),
('Clinic',            'Outpatient only'),
('Urgent Care',       'Walk-in non-emergency'),
('Emergency Room',    'Emergency'),
('Specialty Center',  'Single specialty'),
('Diagnostic Center', 'Lab and imaging'),
('Rehabilitation',    'Physical therapy');


-- ----------------------------------------------------------------------------
-- PHASE 4: VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected output:
--   status                 | icd10 | cpt | specialty | states | facility_types
--   Lookup tables created  |  20   | 20  |    15     |   20   |       7
-- ----------------------------------------------------------------------------
SELECT 'Lookup tables created'                          AS status,
       (SELECT COUNT(*) FROM icd10_codes)               AS icd10_count,
       (SELECT COUNT(*) FROM cpt_codes)                 AS cpt_count,
       (SELECT COUNT(*) FROM specialty_types)           AS specialty_count,
       (SELECT COUNT(*) FROM states)                    AS state_count,
       (SELECT COUNT(*) FROM facility_types)            AS facility_type_count;


-- ============================================================================
-- NEXT FILE:  02_master_tables.sql
-- ============================================================================
