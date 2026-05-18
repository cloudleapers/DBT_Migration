-- ============================================================================
-- FILE:        02_master_tables.sql
-- DATABASE:    PostgreSQL (Supabase) - public schema
-- PURPOSE:     Create master entity tables (facilities, providers, carriers,
--              employees) and seed them. Patient master is created here but
--              POPULATED in 03_transactional_data.sql via generate_series.
-- ESTIMATED:   < 30 seconds
-- ============================================================================
-- WHAT THIS SCRIPT DOES (in order):
--   PHASE 1: Creates 5 master entity tables
--   PHASE 2: Seeds facilities (20 hospitals/clinics)
--   PHASE 3: Seeds providers (50 doctors with NPI numbers)
--   PHASE 4: Seeds insurance carriers (10 payers)
--   PHASE 5: Seeds a small employees set (10 staff for demonstration)
-- ============================================================================
-- DEPENDENCIES:
--   01_lookups.sql must run first (FK references to facility_types,
--   specialty_types, states).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1A: FACILITIES TABLE
-- ----------------------------------------------------------------------------
-- A healthcare facility (hospital, clinic, urgent care, etc).
-- FK to facility_types and states ensures referential integrity.
-- capacity_beds = 0 means outpatient-only.
-- ----------------------------------------------------------------------------
CREATE TABLE facilities (
  facility_id    SERIAL PRIMARY KEY,
  facility_name  VARCHAR(150) NOT NULL,
  type_id        INT REFERENCES facility_types(type_id),
  street_address VARCHAR(200),
  city           VARCHAR(100),
  state_code     CHAR(2) REFERENCES states(state_code),
  zip_code       VARCHAR(10),
  phone          VARCHAR(20),
  capacity_beds  INT,
  is_active      BOOLEAN DEFAULT TRUE,
  opened_date    DATE,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1B: PROVIDERS TABLE
-- ----------------------------------------------------------------------------
-- Healthcare providers (doctors). Each has a unique NPI (National Provider
-- Identifier - the US standard) and a state license.
-- A provider belongs to one specialty and is based at one primary facility.
-- ----------------------------------------------------------------------------
CREATE TABLE providers (
  provider_id    SERIAL PRIMARY KEY,
  npi_number     VARCHAR(15) UNIQUE NOT NULL,
  first_name     VARCHAR(50) NOT NULL,
  last_name      VARCHAR(50) NOT NULL,
  specialty_id   INT REFERENCES specialty_types(specialty_id),
  facility_id    INT REFERENCES facilities(facility_id),
  license_number VARCHAR(30),
  hire_date      DATE,
  is_active      BOOLEAN DEFAULT TRUE,
  email          VARCHAR(150),
  phone          VARCHAR(20),
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1C: PATIENTS TABLE
-- ----------------------------------------------------------------------------
-- Patient master. MRN (Medical Record Number) is the unique business
-- identifier - the value patients see on their wristbands and billing.
-- primary_provider_id captures the patient's PCP relationship.
-- Note: This table is created here but rows are seeded later via
-- generate_series in 03_transactional_data.sql.
-- ----------------------------------------------------------------------------
CREATE TABLE patients (
  patient_id          SERIAL PRIMARY KEY,
  mrn                 VARCHAR(20) UNIQUE NOT NULL,
  first_name          VARCHAR(50) NOT NULL,
  last_name           VARCHAR(50) NOT NULL,
  date_of_birth       DATE NOT NULL,
  gender              CHAR(1) CHECK (gender IN ('M','F','O')),
  race                VARCHAR(50),
  ethnicity           VARCHAR(50),
  street_address      VARCHAR(200),
  city                VARCHAR(100),
  state_code          CHAR(2) REFERENCES states(state_code),
  zip_code            VARCHAR(10),
  phone               VARCHAR(20),
  email               VARCHAR(150),
  primary_provider_id INT REFERENCES providers(provider_id),
  is_active           BOOLEAN DEFAULT TRUE,
  registered_date     DATE,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1D: INSURANCE CARRIERS TABLE
-- ----------------------------------------------------------------------------
-- The insurance companies the facility contracts with. Carrier types
-- distinguish between Commercial, Medicare, Medicaid, and Self-Pay.
-- payer_id is the external ID the facility uses to send claims.
-- ----------------------------------------------------------------------------
CREATE TABLE insurance_carriers (
  carrier_id     SERIAL PRIMARY KEY,
  carrier_name   VARCHAR(100) NOT NULL UNIQUE,
  carrier_type   VARCHAR(30) CHECK (carrier_type IN ('Commercial','Medicare','Medicaid','Self-Pay')),
  payer_id       VARCHAR(20),
  phone          VARCHAR(20),
  is_active      BOOLEAN DEFAULT TRUE,
  contract_start DATE,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 1E: EMPLOYEES TABLE
-- ----------------------------------------------------------------------------
-- Non-provider staff (nurses, techs, billing, etc).
-- Used in extended exercises but minimal in mart layer.
-- ----------------------------------------------------------------------------
CREATE TABLE employees (
  employee_id  SERIAL PRIMARY KEY,
  first_name   VARCHAR(50) NOT NULL,
  last_name    VARCHAR(50) NOT NULL,
  job_title    VARCHAR(80),
  department   VARCHAR(50),
  facility_id  INT REFERENCES facilities(facility_id),
  hire_date    DATE,
  is_active    BOOLEAN DEFAULT TRUE,
  email        VARCHAR(150),
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ----------------------------------------------------------------------------
-- PHASE 2: SEED FACILITIES (20 rows)
-- ----------------------------------------------------------------------------
-- A geographically and type-diverse set:
--   - 6 Hospitals
--   - 6 Clinics
--   - 2 Urgent Care
--   - 1 Emergency Room
--   - 4 Specialty Centers
--   - 1 Diagnostic Center
--   - 1 Rehabilitation
-- type_id matches the SERIAL values from facility_types insert order.
-- ----------------------------------------------------------------------------
INSERT INTO facilities (facility_name, type_id, street_address, city, state_code, zip_code, phone, capacity_beds, opened_date) VALUES
('Cedar Park General Hospital', 1, '1200 Cedar Ave',     'Austin',      'TX', '78701', '512-555-0101', 320, '1998-06-01'),
('Sunshine Medical Center',     1, '450 Palm Blvd',      'Tampa',       'FL', '33602', '813-555-0102', 450, '1985-03-15'),
('Mountain View Clinic',        2, '78 Highland Rd',     'Denver',      'CA', '94016', '415-555-0103', 0,   '2005-11-20'),
('Riverside Family Practice',   2, '23 River St',        'Sacramento',  'CA', '95814', '916-555-0104', 0,   '2010-01-10'),
('Northgate Urgent Care',       3, '500 Northgate Way',  'Seattle',     'WA', '98101', '206-555-0105', 0,   '2015-08-22'),
('Central Hospital ER',         4, '999 Central Ave',    'Chicago',     'IL', '60601', '312-555-0106', 0,   '1995-04-30'),
('Cardiac Specialty Center',    5, '120 Heart Ln',       'Phoenix',     'AZ', '85001', '602-555-0107', 80,  '2008-09-12'),
('Wellness Diagnostic Center',  6, '345 Lab Rd',         'Boston',      'MA', '02108', '617-555-0108', 0,   '2012-05-18'),
('Hope Rehabilitation Center',  7, '67 Recovery Way',    'Atlanta',     'GA', '30301', '404-555-0109', 60,  '2003-12-05'),
('Liberty Community Hospital',  1, '88 Liberty St',      'Philadelphia','PA', '19103', '215-555-0110', 280, '1990-07-20'),
('Sunrise Pediatric Clinic',    2, '15 Childrens Way',   'Houston',     'TX', '77001', '713-555-0111', 0,   '2014-02-14'),
('Lakeside General Hospital',   1, '500 Lake Dr',        'Detroit',     'MI', '48201', '313-555-0112', 380, '1980-10-08'),
('Broadway Womens Center',      5, '200 Broadway',       'New York',    'NY', '10007', '212-555-0113', 50,  '2007-06-25'),
('Pine Valley Clinic',          2, '34 Pine Valley Rd',  'Charlotte',   'NC', '28201', '704-555-0114', 0,   '2018-04-03'),
('Greenfield Surgical Center',  5, '90 Surgery Pl',      'Columbus',    'OH', '43215', '614-555-0115', 30,  '2011-08-17'),
('Harborview Medical Plaza',    1, '1 Harbor Way',       'San Diego',   'CA', '92101', '619-555-0116', 250, '1992-11-11'),
('Westside Walk-in Clinic',     3, '777 West Blvd',      'Los Angeles', 'CA', '90001', '323-555-0117', 0,   '2019-09-30'),
('Trinity Hospital',            1, '101 Trinity Rd',     'Indianapolis','IN', '46201', '317-555-0118', 200, '1987-03-22'),
('Brookside Mental Health',     5, '50 Brookside Way',   'Nashville',   'TN', '37201', '615-555-0119', 40,  '2013-07-14'),
('Cypress Family Medicine',     2, '12 Cypress Ln',      'Jacksonville','FL', '32201', '904-555-0120', 0,   '2016-10-09');


-- ----------------------------------------------------------------------------
-- PHASE 3: SEED PROVIDERS (50 rows)
-- ----------------------------------------------------------------------------
-- 50 providers spread across all 15 specialties and 20 facilities.
-- NPI numbers are sequential placeholders (real NPIs are 10 digits).
-- Hire dates span 2007-2018 to give realistic tenure variation.
-- ----------------------------------------------------------------------------
INSERT INTO providers (npi_number, first_name, last_name, specialty_id, facility_id, license_number, hire_date, email, phone) VALUES
('1234567890','Sarah','Johnson',     1,  1, 'TX-MD-1001','2010-08-15','sarah.johnson@cedarpark.com','512-555-1001'),
('1234567891','Michael','Chen',      4,  1, 'TX-MD-1002','2012-03-20','michael.chen@cedarpark.com','512-555-1002'),
('1234567892','Jessica','Martinez',  3,  11,'TX-MD-1003','2015-09-10','jessica.m@sunrisepeds.com','713-555-1003'),
('1234567893','David','Wilson',      2,  10,'PA-MD-1004','2008-06-25','david.wilson@liberty.com','215-555-1004'),
('1234567894','Lisa','Anderson',     5,  7, 'AZ-MD-1005','2014-01-12','l.anderson@cardiac.com','602-555-1005'),
('1234567895','Robert','Taylor',     8,  15,'OH-MD-1006','2011-11-30','r.taylor@greenfield.com','614-555-1006'),
('1234567896','Emily','Brown',       11, 13,'NY-MD-1007','2013-05-18','e.brown@broadway.com','212-555-1007'),
('1234567897','James','Garcia',      6,  2, 'FL-MD-1008','2009-09-01','j.garcia@sunshine.com','813-555-1008'),
('1234567898','Maria','Rodriguez',   1,  4, 'CA-MD-1009','2016-04-15','m.rodriguez@riverside.com','916-555-1009'),
('1234567899','William','Lee',       12, 6, 'IL-MD-1010','2007-02-28','w.lee@centralhospital.com','312-555-1010'),
('1234567900','Patricia','Davis',    9,  18,'IN-MD-1011','2010-12-10','p.davis@trinity.com','317-555-1011'),
('1234567901','Christopher','Miller',10, 19,'TN-MD-1012','2014-08-22','c.miller@brookside.com','615-555-1012'),
('1234567902','Linda','Wilson',      7,  16,'CA-MD-1013','2012-10-05','l.wilson@harborview.com','619-555-1013'),
('1234567903','Thomas','Moore',      13, 8, 'MA-MD-1014','2015-07-19','t.moore@wellness.com','617-555-1014'),
('1234567904','Barbara','Jackson',   2,  3, 'CA-MD-1015','2008-03-14','b.jackson@mountainview.com','415-555-1015'),
('1234567905','Daniel','White',      4,  16,'CA-MD-1016','2011-09-08','d.white@harborview.com','619-555-1016'),
('1234567906','Susan','Harris',      3,  11,'TX-MD-1017','2017-05-23','s.harris@sunrisepeds.com','713-555-1017'),
('1234567907','Joseph','Clark',      8,  18,'IN-MD-1018','2013-11-17','j.clark@trinity.com','317-555-1018'),
('1234567908','Karen','Lewis',       1,  20,'FL-MD-1019','2018-01-30','k.lewis@cypress.com','904-555-1019'),
('1234567909','Richard','Walker',    14, 1, 'TX-MD-1020','2009-08-12','r.walker@cedarpark.com','512-555-1020'),
('1234567910','Nancy','Hall',        15, 12,'MI-MD-1021','2012-07-04','n.hall@lakeside.com','313-555-1021'),
('1234567911','Steven','Allen',      4,  2, 'FL-MD-1022','2014-04-19','s.allen@sunshine.com','813-555-1022'),
('1234567912','Sandra','Young',      11, 13,'NY-MD-1023','2016-06-11','s.young@broadway.com','212-555-1023'),
('1234567913','Paul','King',         5,  7, 'AZ-MD-1024','2010-10-20','p.king@cardiac.com','602-555-1024'),
('1234567914','Ashley','Wright',     6,  10,'PA-MD-1025','2015-02-08','a.wright@liberty.com','215-555-1025'),
('1234567915','Mark','Lopez',        12, 5, 'WA-MD-1026','2013-08-25','m.lopez@northgate.com','206-555-1026'),
('1234567916','Donna','Hill',        9,  15,'OH-MD-1027','2011-12-15','d.hill@greenfield.com','614-555-1027'),
('1234567917','George','Scott',      7,  8, 'MA-MD-1028','2009-05-30','g.scott@wellness.com','617-555-1028'),
('1234567918','Carol','Green',       1,  14,'NC-MD-1029','2017-09-12','c.green@pinevalley.com','704-555-1029'),
('1234567919','Kenneth','Adams',     10, 19,'TN-MD-1030','2014-11-08','k.adams@brookside.com','615-555-1030'),
('1234567920','Sharon','Baker',      3,  20,'FL-MD-1031','2018-03-22','s.baker@cypress.com','904-555-1031'),
('1234567921','Edward','Nelson',     2,  17,'CA-MD-1032','2010-07-14','e.nelson@westside.com','323-555-1032'),
('1234567922','Betty','Carter',      4,  9, 'GA-MD-1033','2012-02-25','b.carter@hope.com','404-555-1033'),
('1234567923','Brian','Mitchell',    8,  16,'CA-MD-1034','2015-12-03','b.mitchell@harborview.com','619-555-1034'),
('1234567924','Helen','Perez',       11, 11,'TX-MD-1035','2013-04-17','h.perez@sunrisepeds.com','713-555-1035'),
('1234567925','Ronald','Roberts',    13, 8, 'MA-MD-1036','2016-08-10','r.roberts@wellness.com','617-555-1036'),
('1234567926','Deborah','Turner',    6,  18,'IN-MD-1037','2011-01-25','d.turner@trinity.com','317-555-1037'),
('1234567927','Anthony','Phillips',  14, 6, 'IL-MD-1038','2014-06-18','a.phillips@centralhospital.com','312-555-1038'),
('1234567928','Dorothy','Campbell',  15, 12,'MI-MD-1039','2008-09-22','d.campbell@lakeside.com','313-555-1039'),
('1234567929','Kevin','Parker',      1,  3, 'CA-MD-1040','2017-11-05','k.parker@mountainview.com','415-555-1040'),
('1234567930','Cynthia','Evans',     2,  4, 'CA-MD-1041','2015-03-19','c.evans@riverside.com','916-555-1041'),
('1234567931','Jason','Edwards',     5,  2, 'FL-MD-1042','2012-08-07','j.edwards@sunshine.com','813-555-1042'),
('1234567932','Amy','Collins',       3,  18,'IN-MD-1043','2018-05-14','a.collins@trinity.com','317-555-1043'),
('1234567933','Jeffrey','Stewart',   8,  15,'OH-MD-1044','2010-11-28','j.stewart@greenfield.com','614-555-1044'),
('1234567934','Michelle','Sanchez',  9,  19,'TN-MD-1045','2013-07-09','m.sanchez@brookside.com','615-555-1045'),
('1234567935','Gary','Morris',       4,  10,'PA-MD-1046','2009-04-16','g.morris@liberty.com','215-555-1046'),
('1234567936','Laura','Rogers',      11, 13,'NY-MD-1047','2016-10-21','l.rogers@broadway.com','212-555-1047'),
('1234567937','Frank','Reed',        12, 5, 'WA-MD-1048','2011-05-13','f.reed@northgate.com','206-555-1048'),
('1234567938','Donna','Cook',        7,  8, 'MA-MD-1049','2014-09-26','d.cook@wellness.com','617-555-1049'),
('1234567939','Eric','Morgan',       10, 19,'TN-MD-1050','2017-02-11','e.morgan@brookside.com','615-555-1050');


-- ----------------------------------------------------------------------------
-- PHASE 4: SEED INSURANCE CARRIERS (10 rows)
-- ----------------------------------------------------------------------------
-- Mix of major commercial carriers (BCBS, Aetna, UHC, Cigna, Humana, etc),
-- government payers (Medicare, Medicaid), and self-pay.
-- carrier_id 1-7 are Commercial, 8 = Medicare, 9 = Medicaid, 10 = Self-Pay.
-- This pattern is referenced when claims are generated.
-- ----------------------------------------------------------------------------
INSERT INTO insurance_carriers (carrier_name, carrier_type, payer_id, phone, contract_start) VALUES
('Blue Cross Blue Shield','Commercial', 'BCBS001',  '800-555-2001','2015-01-01'),
('Aetna',                 'Commercial', 'AETNA001', '800-555-2002','2015-01-01'),
('UnitedHealthcare',      'Commercial', 'UHC001',   '800-555-2003','2015-01-01'),
('Cigna',                 'Commercial', 'CIGNA001', '800-555-2004','2015-01-01'),
('Humana',                'Commercial', 'HUMANA001','800-555-2005','2015-01-01'),
('Kaiser Permanente',     'Commercial', 'KAISER001','800-555-2006','2016-06-01'),
('Anthem',                'Commercial', 'ANTHEM001','800-555-2007','2015-03-15'),
('Medicare Part A&B',     'Medicare',   'MEDIC001', '800-555-2008','2010-01-01'),
('Medicaid State',        'Medicaid',   'MEDCD001', '800-555-2009','2010-01-01'),
('Self-Pay',              'Self-Pay',   'SELF001',  NULL,           '2010-01-01');


-- ----------------------------------------------------------------------------
-- PHASE 5: SEED EMPLOYEES (10 rows - representative sample)
-- ----------------------------------------------------------------------------
INSERT INTO employees (first_name, last_name, job_title, department, facility_id, hire_date, email) VALUES
('Janet',  'Bailey',   'Registered Nurse',     'Nursing',         1,  '2018-03-15', 'jbailey@cedarpark.com'),
('Robert', 'Cooper',   'Medical Technologist', 'Lab',             8,  '2016-07-22', 'rcooper@wellness.com'),
('Mary',   'Foster',   'Receptionist',         'Front Office',    3,  '2020-01-10', 'mfoster@mountainview.com'),
('Charles','Russell',  'Pharmacist',           'Pharmacy',        2,  '2014-05-30', 'crussell@sunshine.com'),
('Sarah',  'Hughes',   'Medical Coder',        'Billing',         10, '2019-09-08', 'shughes@liberty.com'),
('Henry',  'Bryant',   'Radiology Technician', 'Imaging',         8,  '2017-11-14', 'hbryant@wellness.com'),
('Jennifer','Russell', 'Medical Assistant',    'Clinical',        4,  '2021-02-25', 'jrussell@riverside.com'),
('Larry',  'Diaz',     'Billing Specialist',   'Billing',         12, '2018-08-20', 'ldiaz@lakeside.com'),
('Anna',   'Gonzalez', 'Lab Tech',             'Lab',             16, '2019-06-12', 'agonzalez@harborview.com'),
('Walter', 'Sullivan', 'IT Support',           'Technology',      1,  '2015-04-18', 'wsullivan@cedarpark.com');


-- ----------------------------------------------------------------------------
-- PHASE 6: VERIFICATION
-- ----------------------------------------------------------------------------
-- Expected output:
--   status                | facilities | providers | carriers | employees
--   Master tables created |    20      |    50     |    10    |    10
-- ----------------------------------------------------------------------------
SELECT 'Master tables created'                    AS status,
       (SELECT COUNT(*) FROM facilities)          AS facilities,
       (SELECT COUNT(*) FROM providers)           AS providers,
       (SELECT COUNT(*) FROM insurance_carriers)  AS carriers,
       (SELECT COUNT(*) FROM employees)           AS employees;


-- ============================================================================
-- NEXT FILE:  03_transactional_data.sql
-- ============================================================================
