-- ============================================================================
-- FILE:        03_transactional_data.sql
-- DATABASE:    PostgreSQL (Supabase) - public schema
-- PURPOSE:     Create transactional tables and bulk-generate ~75K rows of
--              realistic synthetic clinical activity using generate_series.
-- ESTIMATED:   60-90 seconds (the generators run sequentially)
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   PHASE 1: Creates 8 transactional tables (encounters, diagnoses,
--            procedures, prescriptions, labs, vitals, allergies)
--   PHASE 2: Generates 5,000 patients via generate_series
--   PHASE 3: Generates 20,000 encounters (visits) for those patients
--   PHASE 4: Generates 20,000 diagnoses (one primary per encounter)
--   PHASE 5: Generates 20,000 procedures (one per encounter)
--   PHASE 6: Generates ~6,666 prescriptions (every 3rd encounter)
--   PHASE 7: Generates ~5,000 lab orders (every 4th encounter)
--   PHASE 8: Generates ~4,500 lab results (90% of completed orders)
--   PHASE 9: Generates 20,000 vitals records (one per encounter)
--   PHASE 10: Generates 1,250 allergies (every 4th patient)
-- ============================================================================
-- DESIGN NOTES:
--   - generate_series + modulo arithmetic produces deterministic distributions
--     so the data is repeatable across runs.
--   - Date ranges roll back from CURRENT_DATE so data always looks "recent"
--     regardless of when the script is run.
--   - Patient/provider/facility IDs are spread evenly (g % N) for clean
--     analytical distributions.
-- ============================================================================
-- DEPENDENCIES:
--   01_lookups.sql AND 02_master_tables.sql must run first.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1A: ENCOUNTERS TABLE
-- ----------------------------------------------------------------------------
-- Each encounter is one patient visit. encounter_type drives clinical
-- categorization. duration_minutes is meaningful for capacity planning.
-- ----------------------------------------------------------------------------
CREATE TABLE encounters (
  encounter_id     SERIAL PRIMARY KEY,
  encounter_number VARCHAR(20) UNIQUE NOT NULL,
  patient_id       INT NOT NULL REFERENCES patients(patient_id),
  provider_id      INT NOT NULL REFERENCES providers(provider_id),
  facility_id      INT NOT NULL REFERENCES facilities(facility_id),
  encounter_type   VARCHAR(30) CHECK (encounter_type IN ('Office Visit','Emergency','Inpatient','Telehealth','Wellness','Urgent Care')),
  encounter_date   DATE NOT NULL,
  encounter_time   TIME,
  duration_minutes INT,
  chief_complaint  TEXT,
  status           VARCHAR(20) DEFAULT 'Completed',
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1B: ENCOUNTER_DIAGNOSES TABLE
-- ----------------------------------------------------------------------------
-- Many-to-one with encounters. A single encounter can have:
--   - 1 Primary diagnosis (the chief medical reason)
--   - 0..many Secondary diagnoses
--   - 0..many Admitting diagnoses (inpatient only)
-- ----------------------------------------------------------------------------
CREATE TABLE encounter_diagnoses (
  diagnosis_id   SERIAL PRIMARY KEY,
  encounter_id   INT NOT NULL REFERENCES encounters(encounter_id),
  icd10_code     VARCHAR(10) NOT NULL REFERENCES icd10_codes(code),
  diagnosis_type VARCHAR(20) DEFAULT 'Primary' CHECK (diagnosis_type IN ('Primary','Secondary','Admitting')),
  diagnosed_date DATE NOT NULL,
  notes          TEXT,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1C: ENCOUNTER_PROCEDURES TABLE
-- ----------------------------------------------------------------------------
-- Procedures performed during an encounter. Each row has a CPT code
-- (links to billing) and a charge_amount (provider's listed price).
-- ----------------------------------------------------------------------------
CREATE TABLE encounter_procedures (
  procedure_id   SERIAL PRIMARY KEY,
  encounter_id   INT NOT NULL REFERENCES encounters(encounter_id),
  cpt_code       VARCHAR(10) NOT NULL REFERENCES cpt_codes(code),
  performed_by   INT REFERENCES providers(provider_id),
  performed_date DATE NOT NULL,
  units          INT DEFAULT 1,
  charge_amount  NUMERIC(10,2),
  notes          TEXT,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1D: PRESCRIPTIONS TABLE
-- ----------------------------------------------------------------------------
-- Medications prescribed during an encounter. is_controlled flags
-- DEA-controlled substances (opioids, benzos, etc).
-- ----------------------------------------------------------------------------
CREATE TABLE prescriptions (
  prescription_id SERIAL PRIMARY KEY,
  encounter_id    INT REFERENCES encounters(encounter_id),
  patient_id      INT NOT NULL REFERENCES patients(patient_id),
  provider_id     INT NOT NULL REFERENCES providers(provider_id),
  medication_name VARCHAR(150) NOT NULL,
  dosage          VARCHAR(50),
  frequency       VARCHAR(50),
  duration_days   INT,
  refills         INT DEFAULT 0,
  prescribed_date DATE NOT NULL,
  is_controlled   BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1E: LAB ORDERS + RESULTS (two tables, one-to-one ish)
-- ----------------------------------------------------------------------------
-- An order is the request, a result is the lab's response. Some orders
-- never produce a result (status = 'Pending' or 'Cancelled').
-- ----------------------------------------------------------------------------
CREATE TABLE lab_orders (
  lab_order_id SERIAL PRIMARY KEY,
  encounter_id INT REFERENCES encounters(encounter_id),
  patient_id   INT NOT NULL REFERENCES patients(patient_id),
  provider_id  INT NOT NULL REFERENCES providers(provider_id),
  test_name    VARCHAR(100) NOT NULL,
  test_code    VARCHAR(20),
  ordered_date DATE NOT NULL,
  status       VARCHAR(20) DEFAULT 'Ordered',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lab_results (
  result_id       SERIAL PRIMARY KEY,
  lab_order_id    INT NOT NULL REFERENCES lab_orders(lab_order_id),
  result_value    VARCHAR(50),
  result_unit     VARCHAR(20),
  reference_range VARCHAR(50),
  is_abnormal     BOOLEAN DEFAULT FALSE,
  result_date     DATE NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1F: VITALS TABLE
-- ----------------------------------------------------------------------------
-- Vital signs measured during an encounter. bp_classification is computed
-- in the staging dbt model from systolic/diastolic.
-- ----------------------------------------------------------------------------
CREATE TABLE vitals (
  vital_id          SERIAL PRIMARY KEY,
  encounter_id      INT NOT NULL REFERENCES encounters(encounter_id),
  patient_id        INT NOT NULL REFERENCES patients(patient_id),
  measured_date     DATE NOT NULL,
  systolic_bp       INT,
  diastolic_bp      INT,
  heart_rate        INT,
  respiratory_rate  INT,
  temperature_f     NUMERIC(4,1),
  weight_kg         NUMERIC(5,2),
  height_cm         NUMERIC(5,2),
  oxygen_saturation INT,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1G: ALLERGIES TABLE
-- ----------------------------------------------------------------------------
-- Patient-level (NOT encounter-level) - allergies persist across visits.
-- ----------------------------------------------------------------------------
CREATE TABLE allergies (
  allergy_id      SERIAL PRIMARY KEY,
  patient_id      INT NOT NULL REFERENCES patients(patient_id),
  allergen        VARCHAR(100) NOT NULL,
  reaction        VARCHAR(200),
  severity        VARCHAR(20) CHECK (severity IN ('Mild','Moderate','Severe')),
  identified_date DATE,
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 2: GENERATE 5,000 PATIENTS
-- ----------------------------------------------------------------------------
-- Uses generate_series(1, 5000) to produce sequential patient numbers,
-- then maps to realistic-looking values via modulo on arrays:
--   - first_name, last_name picked from arrays of common US names
--   - date_of_birth: distributed across ages 1-80 years
--   - gender: alternating M/F
--   - city/state: distributed across 20 US cities
--   - primary_provider_id: rotates through 50 providers
-- This produces a deterministic-but-varied dataset perfect for analytics.
-- ----------------------------------------------------------------------------
INSERT INTO patients (mrn, first_name, last_name, date_of_birth, gender, race, ethnicity, street_address, city, state_code, zip_code, phone, email, primary_provider_id, registered_date)
SELECT
  'MRN' || LPAD(g::TEXT, 7, '0'),
  (ARRAY['John','Mary','Robert','Patricia','Michael','Jennifer','William','Linda','David','Elizabeth','James','Barbara','Richard','Susan','Joseph','Jessica','Thomas','Sarah','Charles','Karen','Daniel','Nancy','Matthew','Lisa','Donald','Betty','Mark','Helen','Paul','Sandra','Steven','Donna','Andrew','Carol','Kenneth','Ruth','George','Sharon','Joshua','Michelle','Kevin','Laura','Brian','Sarah','Edward','Kimberly','Ronald','Deborah','Anthony','Dorothy'])[(g % 50) + 1],
  (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson','Walker','Young','Allen','King','Wright','Scott','Torres','Nguyen','Hill','Flores','Green','Adams','Nelson','Baker','Hall','Rivera','Campbell','Mitchell','Carter','Roberts'])[(g % 50) + 1],
  CURRENT_DATE - ((g % 80 + 1) * 365 + (g % 365))::INT,
  CASE WHEN g % 2 = 0 THEN 'M' ELSE 'F' END,
  (ARRAY['White','Black or African American','Asian','American Indian','Other','White','White','Black or African American'])[(g % 8) + 1],
  CASE WHEN g % 4 = 0 THEN 'Hispanic or Latino' ELSE 'Not Hispanic or Latino' END,
  (g * 17 % 999 + 1) || ' Main St',
  (ARRAY['Austin','Tampa','Denver','Sacramento','Seattle','Chicago','Phoenix','Boston','Atlanta','Philadelphia','Houston','Detroit','New York','Charlotte','Columbus','San Diego','Los Angeles','Indianapolis','Nashville','Jacksonville'])[(g % 20) + 1],
  (ARRAY['TX','FL','CA','CA','WA','IL','AZ','MA','GA','PA','TX','MI','NY','NC','OH','CA','CA','IN','TN','FL'])[(g % 20) + 1],
  LPAD((g % 99999)::TEXT, 5, '0'),
  '555-' || LPAD(((g * 13) % 9999)::TEXT, 4, '0'),
  'patient' || g || '@email.com',
  ((g % 50) + 1),
  CURRENT_DATE - ((g % 1825) + 1)
FROM generate_series(1, 5000) g;


-- ----------------------------------------------------------------------------
-- PHASE 3: GENERATE 20,000 ENCOUNTERS
-- ----------------------------------------------------------------------------
-- Each patient averages 4 encounters (5000 * 4 = 20000).
-- encounter_date spans the past 730 days (2 years) for trend analysis.
-- encounter_type is biased toward Office Visits (most common in real data).
-- ----------------------------------------------------------------------------
INSERT INTO encounters (encounter_number, patient_id, provider_id, facility_id, encounter_type, encounter_date, encounter_time, duration_minutes, chief_complaint)
SELECT
  'ENC' || LPAD(g::TEXT, 8, '0'),
  ((g % 5000) + 1),
  ((g % 50) + 1),
  ((g % 20) + 1),
  (ARRAY['Office Visit','Office Visit','Office Visit','Wellness','Emergency','Telehealth','Urgent Care','Inpatient'])[(g % 8) + 1],
  CURRENT_DATE - ((g % 730) + 1),
  ('08:00:00'::TIME + ((g % 480) || ' minutes')::INTERVAL)::TIME,
  (15 + (g % 75)),
  (ARRAY['Routine checkup','Chest pain','Headache','Back pain','Cough','Diabetes follow-up','Hypertension follow-up','Sore throat','Fever','Abdominal pain','Joint pain','Fatigue','Anxiety','Allergy symptoms','Dizziness'])[(g % 15) + 1]
FROM generate_series(1, 20000) g;


-- ----------------------------------------------------------------------------
-- PHASE 4: GENERATE ENCOUNTER DIAGNOSES (1 per encounter)
-- ----------------------------------------------------------------------------
-- Maps each encounter to one of the 20 ICD-10 codes via modulo.
-- Every 4th diagnosis is marked as Secondary; rest are Primary.
-- ----------------------------------------------------------------------------
INSERT INTO encounter_diagnoses (encounter_id, icd10_code, diagnosis_type, diagnosed_date)
SELECT
  e.encounter_id,
  (ARRAY['E11.9','I10','J45.909','M54.5','K21.9','F32.9','N18.9','I25.10','E78.5','J44.9','M17.0','G43.909','R50.9','R10.9','J06.9','B34.9','S93.401','Z00.00','Z23','O80'])[((e.encounter_id % 20) + 1)],
  CASE WHEN e.encounter_id % 4 = 0 THEN 'Secondary' ELSE 'Primary' END,
  e.encounter_date
FROM encounters e;


-- ----------------------------------------------------------------------------
-- PHASE 5: GENERATE ENCOUNTER PROCEDURES (1 per encounter)
-- ----------------------------------------------------------------------------
-- Maps each encounter to one CPT code with charge_amount = base_cost.
-- ----------------------------------------------------------------------------
INSERT INTO encounter_procedures (encounter_id, cpt_code, performed_by, performed_date, units, charge_amount)
SELECT
  e.encounter_id,
  (ARRAY['99213','99214','99203','99396','99397','80053','80061','85025','83036','93000','71046','72148','45378','27447','29881','90471','90686','99281','99284','59400'])[((e.encounter_id % 20) + 1)],
  e.provider_id,
  e.encounter_date,
  1,
  (ARRAY[95.00,130.00,145.00,175.00,195.00,35.00,28.00,22.00,25.00,75.00,110.00,850.00,950.00,18500.00,4200.00,35.00,45.00,250.00,650.00,4500.00])[((e.encounter_id % 20) + 1)]
FROM encounters e;


-- ----------------------------------------------------------------------------
-- PHASE 6: GENERATE PRESCRIPTIONS (every 3rd encounter ~ 6,666 rows)
-- ----------------------------------------------------------------------------
-- Mix of common chronic and acute medications.
-- Every 15th prescription is flagged as controlled substance.
-- ----------------------------------------------------------------------------
INSERT INTO prescriptions (encounter_id, patient_id, provider_id, medication_name, dosage, frequency, duration_days, refills, prescribed_date, is_controlled)
SELECT
  e.encounter_id,
  e.patient_id,
  e.provider_id,
  (ARRAY['Metformin','Lisinopril','Atorvastatin','Levothyroxine','Amlodipine','Metoprolol','Albuterol','Omeprazole','Losartan','Gabapentin','Sertraline','Hydrochlorothiazide','Simvastatin','Montelukast','Tramadol'])[((e.encounter_id % 15) + 1)],
  (ARRAY['500mg','10mg','20mg','50mcg','5mg','25mg','90mcg','40mg','25mg','300mg','50mg','12.5mg','40mg','10mg','50mg'])[((e.encounter_id % 15) + 1)],
  (ARRAY['Once daily','Twice daily','Three times daily','Every 4 hours','As needed','Once daily at bedtime','Twice daily','Once daily','Twice daily','Once daily','Once daily','Once daily','Once daily at bedtime','Once daily at bedtime','Every 6 hours as needed'])[((e.encounter_id % 15) + 1)],
  (30 + (e.encounter_id % 60)),
  (e.encounter_id % 6),
  e.encounter_date,
  CASE WHEN e.encounter_id % 15 = 14 THEN TRUE ELSE FALSE END
FROM encounters e
WHERE e.encounter_id % 3 = 0;


-- ----------------------------------------------------------------------------
-- PHASE 7: GENERATE LAB ORDERS (every 4th encounter ~ 5,000 rows)
-- ----------------------------------------------------------------------------
-- Every 10th order is left as 'Pending' (no result yet).
-- ----------------------------------------------------------------------------
INSERT INTO lab_orders (encounter_id, patient_id, provider_id, test_name, test_code, ordered_date, status)
SELECT
  e.encounter_id,
  e.patient_id,
  e.provider_id,
  (ARRAY['Comprehensive Metabolic Panel','Lipid Panel','CBC with Diff','Hemoglobin A1c','TSH','Urinalysis','Liver Function Test','Vitamin D','PSA','Pregnancy Test'])[((e.encounter_id % 10) + 1)],
  (ARRAY['80053','80061','85025','83036','84443','81001','80076','82306','84153','84703'])[((e.encounter_id % 10) + 1)],
  e.encounter_date,
  CASE WHEN e.encounter_id % 10 = 0 THEN 'Pending' ELSE 'Completed' END
FROM encounters e
WHERE e.encounter_id % 4 = 0;


-- ----------------------------------------------------------------------------
-- PHASE 8: GENERATE LAB RESULTS (only for completed orders)
-- ----------------------------------------------------------------------------
-- Every 5th result is flagged abnormal - drives clinical alerts.
-- result_date is order_date + 1 day to simulate lab turnaround.
-- ----------------------------------------------------------------------------
INSERT INTO lab_results (lab_order_id, result_value, result_unit, reference_range, is_abnormal, result_date)
SELECT
  l.lab_order_id,
  (50 + (l.lab_order_id % 200))::TEXT,
  (ARRAY['mg/dL','mmol/L','%','U/L','ng/mL','count','mg/dL','mmol/L','%','U/L'])[((l.lab_order_id % 10) + 1)],
  '70-100',
  CASE WHEN l.lab_order_id % 5 = 0 THEN TRUE ELSE FALSE END,
  l.ordered_date + INTERVAL '1 day'
FROM lab_orders l
WHERE l.status = 'Completed';


-- ----------------------------------------------------------------------------
-- PHASE 9: GENERATE VITALS (1 per encounter)
-- ----------------------------------------------------------------------------
-- Distributions are intentionally varied so some are hypertensive, some
-- elevated, and some normal - drives bp_classification analytics.
-- ----------------------------------------------------------------------------
INSERT INTO vitals (encounter_id, patient_id, measured_date, systolic_bp, diastolic_bp, heart_rate, respiratory_rate, temperature_f, weight_kg, height_cm, oxygen_saturation)
SELECT
  e.encounter_id,
  e.patient_id,
  e.encounter_date,
  100 + (e.encounter_id % 60),
  60 + (e.encounter_id % 30),
  60 + (e.encounter_id % 40),
  12 + (e.encounter_id % 8),
  97.0 + ((e.encounter_id % 30) * 0.1),
  50.0 + (e.encounter_id % 50),
  150.0 + (e.encounter_id % 40),
  95 + (e.encounter_id % 5)
FROM encounters e;


-- ----------------------------------------------------------------------------
-- PHASE 10: GENERATE ALLERGIES (every 4th patient ~ 1,250 rows)
-- ----------------------------------------------------------------------------
-- 10 common allergens, 10 reaction types, 5 severity levels.
-- ----------------------------------------------------------------------------
INSERT INTO allergies (patient_id, allergen, reaction, severity, identified_date)
SELECT
  p.patient_id,
  (ARRAY['Penicillin','Sulfa drugs','Aspirin','Latex','Peanuts','Shellfish','Dairy','Eggs','Pollen','Bee stings'])[((p.patient_id % 10) + 1)],
  (ARRAY['Hives','Difficulty breathing','Swelling','Rash','Anaphylaxis','Nausea','Itching','Wheezing','Sneezing','Severe pain'])[((p.patient_id % 10) + 1)],
  (ARRAY['Mild','Moderate','Severe','Mild','Moderate'])[((p.patient_id % 5) + 1)],
  CURRENT_DATE - ((p.patient_id % 3650) + 1)
FROM patients p
WHERE p.patient_id % 4 = 0;


-- ----------------------------------------------------------------------------
-- PHASE 11: VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected output:
--   patients: 5000   encounters: 20000   diagnoses: 20000   procedures: 20000
--   prescriptions: ~6666   lab_orders: 5000   lab_results: ~4500
--   vitals: 20000   allergies: 1250
-- ----------------------------------------------------------------------------
SELECT 'Transactional tables loaded'                     AS status,
       (SELECT COUNT(*) FROM patients)                   AS patients,
       (SELECT COUNT(*) FROM encounters)                 AS encounters,
       (SELECT COUNT(*) FROM encounter_diagnoses)        AS diagnoses,
       (SELECT COUNT(*) FROM encounter_procedures)       AS procedures,
       (SELECT COUNT(*) FROM prescriptions)              AS prescriptions,
       (SELECT COUNT(*) FROM lab_orders)                 AS lab_orders,
       (SELECT COUNT(*) FROM lab_results)                AS lab_results,
       (SELECT COUNT(*) FROM vitals)                     AS vitals,
       (SELECT COUNT(*) FROM allergies)                  AS allergies;


-- ============================================================================
-- NEXT FILE:  04_views.sql
-- ============================================================================
