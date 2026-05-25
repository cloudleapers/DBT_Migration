-- =====================================================================
-- DBT TRAINING ASSIGNMENT - SOURCE DATA (Supabase Postgres)
-- Healthcare Clinic Network
-- Run in Supabase SQL Editor (public schema).
--
-- Data deliberately contains:
--   * Dirty names: John123, Smith_xfh, trailing spaces, special chars
--   * Mixed date/flag formats, NULLs, duplicates, orphan FKs, negatives
--   * "Version 2" rows are applied via UPDATE blocks at the bottom so
--     SNAPSHOTS have real changes to capture (run them on day 2).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CLINICS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.clinics CASCADE;
CREATE TABLE public.clinics (
    clinic_id      INTEGER PRIMARY KEY,
    clinic_name    VARCHAR(100),
    city           VARCHAR(50),
    state          VARCHAR(50),
    is_operational VARCHAR(5),      -- Y/N/1/0 mix
    opened_date    VARCHAR(20),
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.clinics VALUES
(1, 'CloudCare Central',   'Hyderabad', 'Telangana',   'Y', '2020-01-15', NOW()),
(2, 'CloudCare North',     'Delhi',     'Delhi',       'Y', '2021-03-10', NOW()),
(3, 'CloudCare West',      'Mumbai',    'Maharashtra', '1', '2021-06-22', NOW()),
(4, 'CloudCare South',     'Chennai',   'Tamil Nadu',  'Y', '2022-09-05', NOW()),
(5, 'CloudCare Test Site', 'Test',      'Test',        'N', 'INVALID',    NOW());  -- garbage row

-- ---------------------------------------------------------------------
-- 2. PATIENTS   (dirty names + messy data + SCD-2 candidates)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.patients CASCADE;
CREATE TABLE public.patients (
    patient_id     INTEGER PRIMARY KEY,
    first_name     VARCHAR(50),
    last_name      VARCHAR(50),
    email          VARCHAR(150),
    phone          VARCHAR(30),
    city           VARCHAR(50),
    date_of_birth  VARCHAR(20),
    gender         VARCHAR(10),
    plan_id        INTEGER,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.patients VALUES
(101, 'John123',     'Smith_xfh',   '  JOHN.smith@gmail.com ', '+91-9876543210', 'Hyderabad', '1985-03-15', 'M',      1, NOW()),  -- dirty name
(102, 'Priya  ',     'Sharma',      'priya.sharma@yahoo.com',  '9876500000',     'Mumbai',    '1990/07/22', 'Female', 2, NOW()),  -- trailing space
(103, 'Mary  Jane',  'Wilson',      'mary.wilson@hotmail.com', '+91-9988776655', 'Delhi',     '1978-11-30', 'F',      1, NOW()),  -- double space
(104, 'ravi@@',      'kumar!!',     'ravi.kumar@gmail.com',    '+91-9000011111', 'Chennai',   '1992-12-03', 'Male',   3, NOW()),  -- special chars
(105, 'O''Brien',    'Anne-Marie',  'obrien@gmail.com',        '+91-9123456780', 'Hyderabad', '1988-05-18', 'F',      2, NOW()),  -- legit apostrophe/hyphen (keep)
(106, 'David',       'Brown',       'david@@gmail.com',        NULL,             'Mumbai',    '1982-09-12', 'M',      1, NOW()),  -- bad email
(107, 'Karthik99',   'Rao_123',     'karthik.rao@gmail.com',   '+91-9444455555', 'Delhi',     '15-07-1988', 'Male',   NULL, NOW()),-- dirty + dd-mm-yyyy
(108, 'Sara',        'Lee',         'sara.lee@gmail.com',      '+91-9555566666', 'Chennai',   '2001-04-08', 'Female', 3, NOW()),
(109, 'Test',        'User',        'test@test',               '0000000000',     'Test',      'INVALID',    'X',      1, NOW()),  -- garbage row
(110, 'John123',     'Smith_xfh',   'JOHN.smith@gmail.com',    '+91-9876543210', 'Hyderabad', '1985-03-15', 'M',      1, NOW()),  -- duplicate of 101 (same email after cleaning)
(111, 'Lakshmi',     'Devi  ',      'lakshmi.devi@gmail.com',  '+91-9222233333', 'Hyderabad', '1975-08-19', 'F',      2, NOW()),
(112, 'Mike#$%',     'Johnson',     'mike.j@gmail.com',        '+91-9333344444', 'Mumbai',    '1998-02-14', 'Male',   1, NOW());  -- special chars

-- ---------------------------------------------------------------------
-- 3. DOCTORS   (fee changes for SCD-2)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.doctors CASCADE;
CREATE TABLE public.doctors (
    doctor_id        INTEGER PRIMARY KEY,
    doctor_name      VARCHAR(100),
    specialization   VARCHAR(80),
    clinic_id        INTEGER,
    consultation_fee NUMERIC(10,2),
    is_available     VARCHAR(5),
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.doctors VALUES
(201, 'Dr. Suresh Babu',   'Cardiology',      1, 800.00,  'Y', NOW()),
(202, 'Dr. Kavya Menon',   'Pediatrics',      2, 500.00,  '1', NOW()),
(203, 'Dr. Arun Prakash',  'Orthopedics',     3, 700.00,  'Y', NOW()),
(204, '  Dr. Neha Gupta ', 'Dermatology',     1, 600.00,  'Y', NOW()),  -- whitespace
(205, 'Dr. Ramesh Iyer',   'Neurology',       4, 1200.00, 'Y', NOW()),
(206, 'Dr. Sneha Patil',   'Gynecology',      2, 750.00,  '0', NOW()),
(207, 'Dr. Test',          'TEST',            5, -100.00, 'N', NOW());  -- invalid row

-- ---------------------------------------------------------------------
-- 4. APPOINTMENTS   (status transitions for SCD-2)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.appointments CASCADE;
CREATE TABLE public.appointments (
    appointment_id   INTEGER PRIMARY KEY,
    patient_id       INTEGER,
    doctor_id        INTEGER,
    clinic_id        INTEGER,
    appointment_date DATE,
    appointment_type VARCHAR(30),
    status           VARCHAR(20),
    fee_charged      NUMERIC(10,2),
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.appointments VALUES
(5001, 101, 201, 1, '2025-01-15', 'Consultation', 'SCHEDULED', 800.00,  NOW()),
(5002, 102, 202, 2, '2025-01-16', 'Follow-up',    'COMPLETED', 500.00,  NOW()),
(5003, 103, 201, 1, '2025-01-18', 'Consultation', 'COMPLETED', 800.00,  NOW()),
(5004, 104, 203, 3, '2025-01-20', 'Consultation', 'SCHEDULED', 700.00,  NOW()),
(5005, 105, 204, 1, '2025-01-22', 'Consultation', 'completed', 600.00,  NOW()),  -- lowercase
(5006, 106, 202, 2, '2025-01-25', 'Follow-up',    'CANCELLED', 0.00,    NOW()),
(5007, 107, 205, 4, '2025-02-01', 'Consultation', 'SCHEDULED', 1200.00, NOW()),
(5008, 108, 203, 3, '2025-02-03', 'Consultation', 'COMPLETED', 700.00,  NOW()),
(5009, 111, 206, 2, '2025-02-05', 'Consultation', 'COMPLETED', 750.00,  NOW()),
(5010, 112, 201, 1, '2025-02-08', 'Follow-up',    'SCHEDULED', 800.00,  NOW()),
(5011, 109, 207, 5, '2025-02-10', 'Consultation', 'SCHEDULED', -50.00,  NOW()),  -- negative fee
(5012, 999, 201, 1, '2025-02-12', 'Consultation', 'COMPLETED', 800.00,  NOW()),  -- orphan patient
(5013, 101, 888, 1, '2025-02-14', 'Consultation', 'COMPLETED', 800.00,  NOW()),  -- orphan doctor
(5014, 103, 201, 1, NULL,         'Consultation', 'COMPLETED', 800.00,  NOW()),  -- NULL date
(5015, 108, 205, 4, '2025-02-16', 'Consultation', 'SCHEDULED', 1200.00, NOW());

-- ---------------------------------------------------------------------
-- 5. PAYMENTS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.payments CASCADE;
CREATE TABLE public.payments (
    payment_id      INTEGER PRIMARY KEY,
    appointment_id  INTEGER,
    amount_cents    INTEGER,          -- stored in cents (paise) on purpose
    payment_method  VARCHAR(20),
    paid_at         VARCHAR(20),
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.payments VALUES
(7001, 5002, 50000,  'CARD', '2025-01-16', NOW()),
(7002, 5003, 80000,  'UPI',  '2025-01-18', NOW()),
(7003, 5005, 60000,  'CASH', '2025-01-22', NOW()),
(7004, 5008, 70000,  'CARD', '2025-02-03', NOW()),
(7005, 5009, 75000,  'UPI',  '2025-02-05', NOW()),
(7006, 5012, 80000,  'CARD', '2025-02-12', NOW()),
(7007, 5011, -5000,  'CASH', '2025-02-10', NOW()),  -- negative (invalid)
(7008, 8888, 10000,  'UPI',  '2025-02-01', NOW());  -- orphan appointment

-- ---------------------------------------------------------------------
-- 6. INSURANCE_PLANS   (status changes for SCD-2)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS public.insurance_plans CASCADE;
CREATE TABLE public.insurance_plans (
    plan_id      INTEGER PRIMARY KEY,
    plan_name    VARCHAR(80),
    tier         VARCHAR(20),
    monthly_cost NUMERIC(10,2),
    is_active    VARCHAR(5),
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO public.insurance_plans VALUES
(1, 'Basic Health',    'BRONZE', 500.00,  'Y', NOW()),
(2, 'Premium Health',  'SILVER', 1200.00, 'Y', NOW()),
(3, 'Elite Health',    'GOLD',   2500.00, 'Y', NOW()),
(4, 'Legacy Plan',     'BRONZE', 300.00,  'Y', NOW());

-- =====================================================================
-- SANITY CHECK
-- =====================================================================
SELECT 'clinics' t, COUNT(*) n FROM public.clinics
UNION ALL SELECT 'patients', COUNT(*) FROM public.patients
UNION ALL SELECT 'doctors', COUNT(*) FROM public.doctors
UNION ALL SELECT 'appointments', COUNT(*) FROM public.appointments
UNION ALL SELECT 'payments', COUNT(*) FROM public.payments
UNION ALL SELECT 'insurance_plans', COUNT(*) FROM public.insurance_plans;