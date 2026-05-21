-- =====================================================================
-- DBT Migration Practice - POSTGRES SOURCE SETUP
-- Run this in your local/dev Postgres instance
-- Schema: raw_source  (acts as the OLTP source system)
-- =====================================================================

DROP SCHEMA IF EXISTS raw_source CASCADE;
CREATE SCHEMA raw_source;
SET search_path TO raw_source;

-- ---------------------------------------------------------------------
-- 1. CUSTOMERS  (intentionally messy)
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    email           VARCHAR(150),
    phone           VARCHAR(30),
    country         VARCHAR(50),
    signup_date     VARCHAR(20),     -- stored as text on purpose (bad data)
    is_active       VARCHAR(5),      -- 'Y'/'N'/'1'/'0' mix
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers VALUES
(1001, 'Ravi',   'Kumar',    '  RAVI.kumar@gmail.com ', '+91-9876543210', 'India',  '2024-01-15', 'Y', NOW()),
(1002, 'Priya',  'Sharma',   'priya.sharma@yahoo.com',  '9876500000',     'India',  '2024/02/10', '1', NOW()),
(1003, 'John',   'Smith',    'john.smith@hotmail.com',  '+1-415-555-0101','USA',    '2024-03-05', 'Y', NOW()),
(1004, 'Anita',  '  Reddy ', 'anita@@gmail.com',        NULL,             'India',  '2024-04-20', 'N', NOW()),  -- bad email
(1005, 'David',  'Brown',    'david.brown@gmail.com',   '+44-20-7946-0958','UK',    '2024-05-12', 'Y', NOW()),
(1006, NULL,     'Wilson',   'wilson@gmail.com',        '+1-212-555-0199','USA',    '2024-06-01', '0', NOW()),  -- missing first name
(1007, 'Meera',  'Iyer',     'meera.iyer@gmail.com',    '+91-9999988888', 'india',  '15-07-2024', 'Y', NOW()),  -- lowercase country, dd-mm-yyyy
(1008, 'Karthik','Rao',      'karthik.rao@gmail.com',   '+91-9000011111', 'India',  '2024-08-22', 'Y', NOW()),
(1009, 'Sara',   'Lee',      'sara.lee@gmail.com',      '+1-310-555-0123','usa',    '2024-09-10', 'Y', NOW()),
(1010, 'Test',   'User',     'test@test',               '0000000000',     'Test',   'INVALID',    'N', NOW()),  -- garbage row
(1011, 'Ravi',   'Kumar',    'RAVI.kumar@gmail.com',    '+91-9876543210', 'India',  '2024-01-15', 'Y', NOW()),  -- duplicate of 1001 (different id, same email)
(1012, 'Lakshmi','Devi',     'lakshmi.devi@gmail.com',  '+91-9123456780', 'India',  '2024-10-18', 'Y', NOW()),
(1013, 'Mike',   'Johnson',  'mike.j@gmail.com',        '+1-646-555-0177','USA',    '2024-11-02', 'Y', NOW()),
(1014, 'Aisha',  'Khan',     'aisha.khan@gmail.com',    '+91-9988776655', 'India',  '2024-12-25', 'Y', NOW()),
(1015, 'Robert', 'Taylor',   'robert.taylor@gmail.com', '+44-161-496-0123','UK',    '2025-01-08', 'Y', NOW());

-- ---------------------------------------------------------------------
-- 2. PRODUCTS
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR(150),
    category      VARCHAR(50),
    unit_price    NUMERIC(10,2),
    cost_price    NUMERIC(10,2),
    in_stock      INTEGER,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products VALUES
(2001, 'Wireless Mouse',      'Electronics', 599.00,  300.00, 150,  NOW()),
(2002, 'Mechanical Keyboard', 'Electronics', 2499.00, 1200.00, 45,  NOW()),
(2003, 'USB-C Hub',           'Electronics', 1299.00, 600.00,  80,  NOW()),
(2004, 'Office Chair',        'Furniture',   8999.00, 4500.00, 12,  NOW()),
(2005, 'Standing Desk',       'Furniture',   15999.00,8000.00, 5,   NOW()),
(2006, 'Notebook A5',         'Stationery',  149.00,  60.00,  500,  NOW()),
(2007, 'Gel Pen Pack',        'Stationery',  99.00,   30.00,  1000, NOW()),
(2008, 'Coffee Mug',          'Kitchen',     249.00,  100.00, 200,  NOW()),
(2009, 'Water Bottle',        'Kitchen',     399.00,  150.00, 180,  NOW()),
(2010, 'Discontinued SKU',    NULL,          0.00,    0.00,   0,    NOW()),     -- bad / inactive
(2011, 'Test Product',        'TEST',        -10.00,  -5.00,  -1,   NOW()),     -- negative — invalid
(2012, '  HDMI Cable  ',      'electronics', 349.00,  150.00, 75,   NOW());     -- leading/trailing spaces, lowercase category

-- ---------------------------------------------------------------------
-- 3. ORDERS
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER,
    product_id      INTEGER,
    order_date      DATE,
    quantity        INTEGER,
    unit_price      NUMERIC(10,2),
    discount_pct    NUMERIC(5,2),
    order_status    VARCHAR(20),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders VALUES
(5001, 1001, 2001, '2025-01-10', 2, 599.00,  0,    'COMPLETED', NOW()),
(5002, 1001, 2006, '2025-01-12', 5, 149.00,  10,   'COMPLETED', NOW()),
(5003, 1002, 2002, '2025-01-15', 1, 2499.00, 5,    'COMPLETED', NOW()),
(5004, 1003, 2004, '2025-01-18', 1, 8999.00, 0,    'COMPLETED', NOW()),
(5005, 1004, 2003, '2025-01-20', 2, 1299.00, 0,    'CANCELLED', NOW()),
(5006, 1005, 2005, '2025-01-22', 1, 15999.00,15,   'COMPLETED', NOW()),
(5007, 1006, 2007, '2025-01-25', 10,99.00,   0,    'COMPLETED', NOW()),
(5008, 1007, 2008, '2025-02-01', 3, 249.00,  0,    'RETURNED',  NOW()),
(5009, 1008, 2009, '2025-02-03', 4, 399.00,  0,    'COMPLETED', NOW()),
(5010, 1009, 2001, '2025-02-05', 1, 599.00,  20,   'COMPLETED', NOW()),
(5011, 1010, 2011, '2025-02-08', -2,-10.00,  0,    'PENDING',   NOW()),       -- invalid: negative qty / price
(5012, 1012, 2012, '2025-02-10', 2, 349.00,  0,    'COMPLETED', NOW()),
(5013, 1013, 2002, '2025-02-12', 1, 2499.00, 0,    'COMPLETED', NOW()),
(5014, 1014, 2003, '2025-02-14', 1, 1299.00, 0,    'completed', NOW()),       -- lowercase status
(5015, 1015, 2004, '2025-02-15', 1, 8999.00, 0,    'COMPLETED', NOW()),
(5016, 9999, 2001, '2025-02-16', 1, 599.00,  0,    'COMPLETED', NOW()),       -- orphan: customer_id doesn't exist
(5017, 1001, 8888, '2025-02-17', 1, 0.00,    0,    'COMPLETED', NOW()),       -- orphan: product_id doesn't exist
(5018, 1002, 2006, '2025-02-18', 3, 149.00,  150,  'COMPLETED', NOW()),       -- discount > 100% (invalid)
(5019, 1003, 2007, '2025-02-19', 2, 99.00,   0,    'COMPLETED', NOW()),
(5020, 1004, 2008, '2025-02-20', 1, 249.00,  0,    'COMPLETED', NOW());

-- ---------------------------------------------------------------------
-- Quick sanity check
-- ---------------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders',   COUNT(*) FROM orders;
