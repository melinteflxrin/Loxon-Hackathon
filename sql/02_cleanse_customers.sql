-- ============================================================================
-- CUSTOMER DATA CLEANSING SCRIPT
-- Cleans ST_CUSTOMERS into DW_CUSTOMERS
-- Run after: 01_master_setup.sql
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('CUSTOMER DATA CLEANSING STARTED');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- ============================================================================
-- STEP 1: INSERT AND CLEAN CUSTOMER DATA
-- ============================================================================

INSERT INTO dw_customers (
    customer_id,
    customer_id_raw,
    first_name,
    last_name,
    full_name,
    email,
    email_valid,
    phone,
    phone_cleaned,
    reg_date,
    reg_date_raw
)
SELECT 
    -- Normalize customer_id to numeric
    extract_numeric_id(customer_id) as customer_id,
    customer_id as customer_id_raw,
    
    -- Split full_name into first and last name
    CASE 
        WHEN INSTR(full_name, '/') > 0 THEN 
            TRIM(SUBSTR(full_name, 1, INSTR(full_name, '/') - 1))
        WHEN INSTR(full_name, ' ') > 0 THEN 
            TRIM(SUBSTR(full_name, 1, INSTR(full_name, ' ') - 1))
        ELSE 
            TRIM(full_name)
    END as first_name,
    
    CASE 
        WHEN INSTR(full_name, '/') > 0 THEN 
            TRIM(SUBSTR(full_name, INSTR(full_name, '/') + 1))
        WHEN INSTR(full_name, ' ') > 0 THEN 
            TRIM(SUBSTR(full_name, INSTR(full_name, ' ') + 1))
        ELSE 
            NULL
    END as last_name,
    
    -- Keep original full_name but clean slashes
    REPLACE(full_name, '/', ' ') as full_name,
    
    -- Extract and validate email
    CASE
        -- Handle multiple emails (take first valid one)
        WHEN INSTR(email, ',') > 0 THEN
            TRIM(SUBSTR(email, 1, INSTR(email, ',') - 1))
        -- Handle email with spaces (remove spaces)
        WHEN INSTR(email, ' ') > 0 THEN
            REPLACE(email, ' ', '')
        -- Mark invalid emails as NULL
        WHEN UPPER(email) = 'NOT-AN-EMAIL' THEN
            NULL
        ELSE
            LOWER(TRIM(email))
    END as email,
    
    -- Validate email format
    CASE
        WHEN UPPER(email) = 'NOT-AN-EMAIL' THEN 0
        WHEN INSTR(email, ',') > 0 THEN
            is_valid_email(TRIM(SUBSTR(email, 1, INSTR(email, ',') - 1)))
        WHEN INSTR(email, ' ') > 0 THEN
            is_valid_email(REPLACE(email, ' ', ''))
        ELSE
            is_valid_email(email)
    END as email_valid,
    
    -- Keep raw phone
    phone as phone,
    
    -- Clean phone number
    clean_phone(phone) as phone_cleaned,
    
    -- Parse registration date
    parse_date_multi(reg_date) as reg_date,
    
    -- Keep raw date for reference
    reg_date as reg_date_raw
    
FROM st_customers
WHERE customer_id IS NOT NULL;

COMMIT;

-- ============================================================================
-- STEP 2: HANDLE DUPLICATE CUSTOMER_IDs
-- ============================================================================

-- Find duplicates (same customer_id_raw)
DECLARE
    v_dup_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_dup_count
    FROM (
        SELECT customer_id_raw, COUNT(*) as cnt
        FROM dw_customers
        GROUP BY customer_id_raw
        HAVING COUNT(*) > 1
    );
    
    DBMS_OUTPUT.PUT_LINE('Duplicate raw customer IDs found: ' || v_dup_count);
    
    -- For duplicates, keep the one with the most recent reg_date
    -- Mark others by appending sequence to customer_id
    IF v_dup_count > 0 THEN
        MERGE INTO dw_customers d
        USING (
            SELECT 
                customer_id,
                customer_id_raw,
                ROW_NUMBER() OVER (
                    PARTITION BY customer_id_raw 
                    ORDER BY reg_date DESC NULLS LAST, ROWID
                ) as rn
            FROM dw_customers
        ) src
        ON (d.customer_id = src.customer_id)
        WHEN MATCHED THEN
            UPDATE SET d.customer_id = d.customer_id + (src.rn - 1) * 1000000
            WHERE src.rn > 1;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Duplicates resolved by adding offset to customer_id');
    END IF;
END;
/

-- ============================================================================
-- STEP 3: DATA QUALITY SUMMARY
-- ============================================================================

DECLARE
    v_total NUMBER;
    v_valid_email NUMBER;
    v_invalid_email NUMBER;
    v_valid_phone NUMBER;
    v_valid_date NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM dw_customers;
    
    SELECT COUNT(*) INTO v_valid_email 
    FROM dw_customers WHERE email_valid = 1;
    
    SELECT COUNT(*) INTO v_invalid_email 
    FROM dw_customers WHERE email_valid = 0 OR email IS NULL;
    
    SELECT COUNT(*) INTO v_valid_phone 
    FROM dw_customers WHERE phone_cleaned IS NOT NULL;
    
    SELECT COUNT(*) INTO v_valid_date 
    FROM dw_customers WHERE reg_date IS NOT NULL;
    
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('CUSTOMER DATA QUALITY SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total customers loaded: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Valid emails: ' || v_valid_email || ' (' || ROUND(v_valid_email/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Invalid emails: ' || v_invalid_email || ' (' || ROUND(v_invalid_email/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid phones: ' || v_valid_phone || ' (' || ROUND(v_valid_phone/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid dates: ' || v_valid_date || ' (' || ROUND(v_valid_date/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- Sample cleaned data
SELECT 'Sample of cleaned customer data:' as info FROM DUAL;
SELECT 
    customer_id,
    customer_id_raw,
    first_name,
    last_name,
    email,
    CASE WHEN email_valid = 1 THEN 'Valid' ELSE 'Invalid' END as email_status,
    phone_cleaned,
    reg_date
FROM dw_customers
WHERE ROWNUM <= 10
ORDER BY customer_id;

COMMIT;
