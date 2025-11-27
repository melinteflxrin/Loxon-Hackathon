-- ============================================================================
-- DATA CLEANSING MASTER SCRIPT
-- Oracle 19c SQL for cleaning staging tables into data warehouse layer
-- Execute scripts in order: 1) This file, 2) Customers, 3) Orders, 4) Payments
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE CURRENCY MAPPING TABLE
-- ============================================================================
CREATE TABLE currency_mapping (
    raw_currency VARCHAR2(20),
    clean_currency CHAR(3),
    CONSTRAINT pk_currency_mapping PRIMARY KEY (raw_currency)
);

-- Insert currency mappings
INSERT ALL
    INTO currency_mapping VALUES ('USD', 'USD')
    INTO currency_mapping VALUES ('US$', 'USD')
    INTO currency_mapping VALUES ('EUR', 'EUR')
    INTO currency_mapping VALUES ('EURO', 'EUR')
    INTO currency_mapping VALUES ('HUF', 'HUF')
    INTO currency_mapping VALUES ('', NULL)
    INTO currency_mapping VALUES (NULL, NULL)
SELECT 1 FROM DUAL;

COMMIT;

-- ============================================================================
-- STEP 2: CREATE PAYMENT METHOD MAPPING TABLE
-- ============================================================================
CREATE TABLE payment_method_mapping (
    raw_method VARCHAR2(50),
    clean_method VARCHAR2(20),
    CONSTRAINT pk_payment_method PRIMARY KEY (raw_method)
);

-- Insert payment method mappings
INSERT ALL
    INTO payment_method_mapping VALUES ('Card', 'Card')
    INTO payment_method_mapping VALUES ('CARD', 'Card')
    INTO payment_method_mapping VALUES ('cArD', 'Card')
    INTO payment_method_mapping VALUES ('card', 'Card')
    INTO payment_method_mapping VALUES ('PayPal', 'PayPal')
    INTO payment_method_mapping VALUES ('pay_pal', 'PayPal')
    INTO payment_method_mapping VALUES ('PAYPAL', 'PayPal')
    INTO payment_method_mapping VALUES ('bank_transfer', 'Bank Transfer')
    INTO payment_method_mapping VALUES ('bank-tf', 'Bank Transfer')
    INTO payment_method_mapping VALUES ('BANK_TRANSFER', 'Bank Transfer')
    INTO payment_method_mapping VALUES ('cash', 'Cash')
    INTO payment_method_mapping VALUES ('CASH', 'Cash')
    INTO payment_method_mapping VALUES ('', NULL)
    INTO payment_method_mapping VALUES (NULL, NULL)
SELECT 1 FROM DUAL;

COMMIT;

-- ============================================================================
-- STEP 3: CREATE DATA WAREHOUSE TABLES (CLEAN LAYER)
-- ============================================================================

-- Drop tables if they exist (careful in production!)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_payments CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_orders CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_customers CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Create DW_CUSTOMERS (Clean dimension table)
CREATE TABLE dw_customers (
    customer_id NUMBER PRIMARY KEY,
    customer_id_raw VARCHAR2(50) NOT NULL,
    first_name VARCHAR2(100),
    last_name VARCHAR2(100),
    full_name VARCHAR2(200),
    email VARCHAR2(200),
    email_valid NUMBER(1) DEFAULT 1,  -- 1=valid, 0=invalid
    phone VARCHAR2(20),
    phone_cleaned VARCHAR2(20),
    reg_date DATE,
    reg_date_raw VARCHAR2(50),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT chk_email_valid CHECK (email_valid IN (0,1))
);

COMMENT ON TABLE dw_customers IS 'Cleaned customer dimension table';
COMMENT ON COLUMN dw_customers.customer_id IS 'Numeric surrogate key';
COMMENT ON COLUMN dw_customers.customer_id_raw IS 'Original customer_id from source';
COMMENT ON COLUMN dw_customers.email_valid IS '1 = valid email format, 0 = invalid';

-- Create DW_ORDERS (Clean fact table)
CREATE TABLE dw_orders (
    order_id VARCHAR2(50) PRIMARY KEY,
    customer_id NUMBER,
    customer_id_raw VARCHAR2(50),
    customer_valid NUMBER(1) DEFAULT 1,  -- 1=valid customer, 0=missing/invalid
    order_date DATE,
    order_date_raw VARCHAR2(50),
    amount NUMBER(12,2),
    amount_raw VARCHAR2(50),
    currency CHAR(3),
    currency_raw VARCHAR2(20),
    is_refund NUMBER(1) DEFAULT 0,  -- 1=negative amount (refund), 0=normal
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES dw_customers(customer_id),
    CONSTRAINT chk_customer_valid CHECK (customer_valid IN (0,1)),
    CONSTRAINT chk_is_refund CHECK (is_refund IN (0,1))
);

COMMENT ON TABLE dw_orders IS 'Cleaned orders fact table';
COMMENT ON COLUMN dw_orders.customer_valid IS '1 = valid customer reference, 0 = missing/invalid';
COMMENT ON COLUMN dw_orders.is_refund IS '1 = negative amount (refund), 0 = positive';

-- Create DW_PAYMENTS (Clean fact table)
CREATE TABLE dw_payments (
    payment_id VARCHAR2(50) PRIMARY KEY,
    order_id VARCHAR2(50),
    order_valid NUMBER(1) DEFAULT 1,  -- 1=valid order, 0=missing/invalid
    payment_date DATE,
    payment_date_raw VARCHAR2(50),
    amount NUMBER(12,2),
    amount_raw VARCHAR2(50),
    method VARCHAR2(20),
    method_raw VARCHAR2(50),
    is_duplicate NUMBER(1) DEFAULT 0,  -- 1=duplicate payment_id, 0=unique
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES dw_orders(order_id),
    CONSTRAINT chk_order_valid CHECK (order_valid IN (0,1)),
    CONSTRAINT chk_is_duplicate CHECK (is_duplicate IN (0,1))
);

COMMENT ON TABLE dw_payments IS 'Cleaned payments fact table';
COMMENT ON COLUMN dw_payments.order_valid IS '1 = valid order reference, 0 = missing/invalid';
COMMENT ON COLUMN dw_payments.is_duplicate IS '1 = duplicate payment_id found, 0 = unique';

-- Create indexes for performance
CREATE INDEX idx_orders_customer ON dw_orders(customer_id);
CREATE INDEX idx_orders_date ON dw_orders(order_date);
CREATE INDEX idx_payments_order ON dw_payments(order_id);
CREATE INDEX idx_payments_date ON dw_payments(payment_date);

-- ============================================================================
-- STEP 4: CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to extract numeric customer ID
CREATE OR REPLACE FUNCTION extract_numeric_id(p_raw_id VARCHAR2) 
RETURN NUMBER IS
    v_numeric NUMBER;
BEGIN
    -- Try to extract numbers from the string
    -- CUST1020 -> 1020, 1688 -> 1688, d766ec31 -> use ROWNUM or hash
    v_numeric := REGEXP_REPLACE(p_raw_id, '[^0-9]', '');
    
    IF v_numeric IS NULL OR LENGTH(v_numeric) = 0 THEN
        -- If no numbers, use hash of the string
        v_numeric := ABS(DBMS_UTILITY.GET_HASH_VALUE(p_raw_id, 1000000, 999999999));
    ELSE
        v_numeric := TO_NUMBER(v_numeric);
    END IF;
    
    RETURN v_numeric;
EXCEPTION
    WHEN OTHERS THEN
        RETURN ABS(DBMS_UTILITY.GET_HASH_VALUE(p_raw_id, 1000000, 999999999));
END;
/

-- Function to validate email format
CREATE OR REPLACE FUNCTION is_valid_email(p_email VARCHAR2)
RETURN NUMBER IS
BEGIN
    IF p_email IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Basic email regex validation
    IF REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

-- Function to clean phone numbers
CREATE OR REPLACE FUNCTION clean_phone(p_phone VARCHAR2)
RETURN VARCHAR2 IS
    v_cleaned VARCHAR2(20);
BEGIN
    -- Remove all non-digit characters
    v_cleaned := REGEXP_REPLACE(p_phone, '[^0-9]', '');
    
    -- Return NULL if empty or invalid length
    IF v_cleaned IS NULL OR LENGTH(v_cleaned) < 7 OR LENGTH(v_cleaned) > 15 THEN
        RETURN NULL;
    END IF;
    
    RETURN v_cleaned;
END;
/

-- Function to parse dates with multiple formats
CREATE OR REPLACE FUNCTION parse_date_multi(p_date_str VARCHAR2)
RETURN DATE IS
    v_date DATE;
    TYPE date_format_array IS TABLE OF VARCHAR2(30);
    v_formats date_format_array;
BEGIN
    -- Return NULL for invalid values
    IF p_date_str IS NULL OR 
       UPPER(p_date_str) IN ('N/A', 'UNKNOWN', 'NULL', 'TODAY', 'YESTERDAY') THEN
        RETURN NULL;
    END IF;
    
    -- Initialize format array
    v_formats := date_format_array(
        'YYYY-MM-DD',
        'DD/MM/YYYY',
        'MM/DD/YYYY',
        'DD-Mon-YYYY',
        'DD-MM-YYYY',
        'Mon DD, YYYY',
        'DD Month YYYY',
        'YYYY-MM-DD HH24:MI:SS'
    );
    
    -- Try each format
    FOR i IN 1..v_formats.COUNT LOOP
        BEGIN
            v_date := TO_DATE(p_date_str, v_formats(i));
            RETURN v_date;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Try next format
        END;
    END LOOP;
    
    -- If nothing worked, return NULL
    RETURN NULL;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
/

-- Function to clean amount values
CREATE OR REPLACE FUNCTION clean_amount(p_amount_str VARCHAR2)
RETURN NUMBER IS
    v_cleaned VARCHAR2(50);
    v_amount NUMBER;
BEGIN
    IF p_amount_str IS NULL OR UPPER(p_amount_str) IN ('N/A', 'NULL', 'UNKNOWN') THEN
        RETURN NULL;
    END IF;
    
    -- Remove currency symbols, letters, and extra spaces
    v_cleaned := REGEXP_REPLACE(p_amount_str, '[A-Za-z$€£]', '');
    v_cleaned := TRIM(v_cleaned);
    
    -- Convert to number
    BEGIN
        v_amount := TO_NUMBER(v_cleaned);
        RETURN v_amount;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
/

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================
SELECT 'Master setup completed successfully!' AS status FROM DUAL;
SELECT 'Next steps:' AS instructions FROM DUAL;
SELECT '1. Run: @00_create_consistency_log.sql' AS step_0 FROM DUAL;
SELECT '2. Run: @01_validate_consistency.sql' AS step_1 FROM DUAL;
SELECT '3. Run: @02_cleanse_customers.sql' AS step_2 FROM DUAL;
SELECT '4. Run: @03_cleanse_orders.sql' AS step_3 FROM DUAL;
SELECT '5. Run: @04_cleanse_payments.sql' AS step_4 FROM DUAL;
SELECT '6. Run: @05_data_quality_report.sql' AS step_5 FROM DUAL;
