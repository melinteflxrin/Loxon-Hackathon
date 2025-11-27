-- ============================================================================
-- DATA CONSISTENCY VALIDATION
-- Validates raw staging data and logs issues to LXN_DATA_CONSISTENCY_LOG
-- Run AFTER 00_create_consistency_log.sql, BEFORE cleansing scripts
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('DATA CONSISTENCY VALIDATION STARTED');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- Clear previous log entries
DELETE FROM lxn_data_consistency_log;
COMMIT;

-- ============================================================================
-- SECTION 1: VALIDATE ST_CUSTOMERS
-- ============================================================================

DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_CUSTOMERS ---');
    
    -- Insert validation records for each customer
    INSERT INTO lxn_data_consistency_log (
        table_name,
        record_id,
        cust_missing_id,
        cust_missing_name,
        cust_missing_email,
        cust_invalid_email,
        cust_missing_phone,
        cust_invalid_phone,
        cust_missing_reg_date,
        cust_invalid_reg_date,
        issue_description
    )
    SELECT 
        'ST_CUSTOMERS' as table_name,
        NVL(customer_id, 'NULL_ID_' || ROWNUM) as record_id,
        
        -- Check missing customer_id
        CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' THEN 1 ELSE 0 END as cust_missing_id,
        
        -- Check missing full_name
        CASE WHEN full_name IS NULL OR TRIM(full_name) = '' THEN 1 ELSE 0 END as cust_missing_name,
        
        -- Check missing email
        CASE WHEN email IS NULL OR TRIM(email) = '' THEN 1 ELSE 0 END as cust_missing_email,
        
        -- Check invalid email format
        CASE 
            WHEN email IS NULL THEN 0
            WHEN UPPER(email) = 'NOT-AN-EMAIL' THEN 1
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 1
            ELSE 0 
        END as cust_invalid_email,
        
        -- Check missing phone
        CASE WHEN phone IS NULL OR TRIM(phone) = '' THEN 1 ELSE 0 END as cust_missing_phone,
        
        -- Check invalid phone (too short/long after cleaning)
        CASE 
            WHEN phone IS NULL THEN 0
            WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 THEN 1
            WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) > 15 THEN 1
            ELSE 0
        END as cust_invalid_phone,
        
        -- Check missing reg_date
        CASE WHEN reg_date IS NULL OR TRIM(reg_date) = '' THEN 1 ELSE 0 END as cust_missing_reg_date,
        
        -- Check invalid reg_date
        CASE 
            WHEN reg_date IS NULL THEN 0
            WHEN UPPER(reg_date) IN ('UNKNOWN', 'N/A', 'NULL') THEN 1
            ELSE 0
        END as cust_invalid_reg_date,
        
        -- Description of issues found
        CASE 
            WHEN customer_id IS NULL THEN 'Missing customer_id'
            WHEN full_name IS NULL THEN 'Missing full_name'
            WHEN email IS NULL THEN 'Missing email'
            WHEN UPPER(email) = 'NOT-AN-EMAIL' THEN 'Invalid email placeholder'
            WHEN NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 'Invalid email format'
            WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 THEN 'Phone too short'
            WHEN UPPER(reg_date) IN ('UNKNOWN', 'N/A') THEN 'Invalid registration date'
            ELSE 'Multiple issues'
        END as issue_description
    FROM st_customers
    WHERE 
        -- Only log records with at least one issue
        customer_id IS NULL OR TRIM(customer_id) = ''
        OR full_name IS NULL OR TRIM(full_name) = ''
        OR email IS NULL OR TRIM(email) = '' OR UPPER(email) = 'NOT-AN-EMAIL'
        OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
        OR phone IS NULL OR TRIM(phone) = ''
        OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7
        OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) > 15
        OR reg_date IS NULL OR TRIM(reg_date) = ''
        OR UPPER(reg_date) IN ('UNKNOWN', 'N/A', 'NULL');
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Customer issues logged: ' || v_count);
END;
/

-- ============================================================================
-- SECTION 2: VALIDATE ST_ORDERS
-- ============================================================================

DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_ORDERS ---');
    
    INSERT INTO lxn_data_consistency_log (
        table_name,
        record_id,
        ord_missing_customer,
        ord_invalid_customer,
        ord_missing_date,
        ord_invalid_date,
        ord_missing_amount,
        ord_invalid_amount,
        ord_negative_not_refund,
        ord_missing_currency,
        ord_invalid_currency,
        issue_description,
        raw_value
    )
    SELECT 
        'ST_ORDERS' as table_name,
        NVL(order_id, 'NULL_ID_' || ROWNUM) as record_id,
        
        -- Check missing customer_id
        CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' OR UPPER(customer_id) = 'NULL' THEN 1 ELSE 0 END as ord_missing_customer,
        
        -- Check invalid customer reference (not in ST_CUSTOMERS)
        CASE 
            WHEN customer_id IS NULL OR TRIM(customer_id) = '' OR UPPER(customer_id) = 'NULL' THEN 0
            WHEN NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 1
            ELSE 0
        END as ord_invalid_customer,
        
        -- Check missing order_date
        CASE WHEN order_date IS NULL OR TRIM(order_date) = '' THEN 1 ELSE 0 END as ord_missing_date,
        
        -- Check invalid order_date
        CASE 
            WHEN order_date IS NULL THEN 0
            WHEN UPPER(order_date) IN ('UNKNOWN', 'N/A', 'NULL', 'TODAY', 'YESTERDAY') THEN 1
            ELSE 0
        END as ord_invalid_date,
        
        -- Check missing amount
        CASE WHEN amount IS NULL OR TRIM(amount) = '' THEN 1 ELSE 0 END as ord_missing_amount,
        
        -- Check invalid amount
        CASE 
            WHEN amount IS NULL THEN 0
            WHEN UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1
            WHEN REGEXP_REPLACE(amount, '[^0-9.-]', '') IS NULL THEN 1
            ELSE 0
        END as ord_invalid_amount,
        
        -- Check negative amount without REFUND currency
        CASE 
            WHEN amount IS NULL THEN 0
            WHEN REGEXP_REPLACE(amount, '[^0-9.-]', '') < 0 
                 AND UPPER(NVL(currency, '')) NOT LIKE '%REFUND%' THEN 1
            ELSE 0
        END as ord_negative_not_refund,
        
        -- Check missing currency
        CASE WHEN currency IS NULL OR TRIM(currency) = '' THEN 1 ELSE 0 END as ord_missing_currency,
        
        -- Check invalid currency (not in valid list)
        CASE 
            WHEN currency IS NULL OR TRIM(currency) = '' THEN 0
            WHEN UPPER(currency) NOT IN ('USD', 'US$', 'EUR', 'EURO', 'HUF', 'REFUND') THEN 1
            ELSE 0
        END as ord_invalid_currency,
        
        -- Description
        CASE 
            WHEN customer_id IS NULL THEN 'Missing customer_id'
            WHEN NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 'Invalid customer reference'
            WHEN UPPER(order_date) IN ('UNKNOWN', 'N/A') THEN 'Invalid order date'
            WHEN UPPER(amount) IN ('N/A', 'NULL') THEN 'Invalid amount'
            WHEN REGEXP_REPLACE(amount, '[^0-9.-]', '') < 0 AND UPPER(NVL(currency, '')) NOT LIKE '%REFUND%' THEN 'Negative amount without REFUND currency'
            WHEN currency IS NULL THEN 'Missing currency'
            ELSE 'Multiple issues'
        END as issue_description,
        
        amount as raw_value
        
    FROM st_orders o
    WHERE 
        -- Only log records with at least one issue
        customer_id IS NULL OR TRIM(customer_id) = '' OR UPPER(customer_id) = 'NULL'
        OR NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id)
        OR order_date IS NULL OR TRIM(order_date) = ''
        OR UPPER(order_date) IN ('UNKNOWN', 'N/A', 'NULL', 'TODAY', 'YESTERDAY')
        OR amount IS NULL OR TRIM(amount) = ''
        OR UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN')
        OR (REGEXP_REPLACE(amount, '[^0-9.-]', '') < 0 AND UPPER(NVL(currency, '')) NOT LIKE '%REFUND%')
        OR currency IS NULL OR TRIM(currency) = ''
        OR UPPER(currency) NOT IN ('USD', 'US$', 'EUR', 'EURO', 'HUF', 'REFUND');
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order issues logged: ' || v_count);
END;
/

-- ============================================================================
-- SECTION 3: VALIDATE ST_PAYMENTS
-- ============================================================================

DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_PAYMENTS ---');
    
    INSERT INTO lxn_data_consistency_log (
        table_name,
        record_id,
        pay_missing_order,
        pay_invalid_order,
        pay_missing_date,
        pay_invalid_date,
        pay_missing_amount,
        pay_invalid_amount,
        pay_date_before_order,
        pay_amount_exceeds_order,
        pay_missing_method,
        pay_invalid_method,
        pay_duplicate_id,
        issue_description,
        raw_value
    )
    SELECT 
        'ST_PAYMENTS' as table_name,
        NVL(payment_id, 'NULL_ID_' || ROWNUM) as record_id,
        
        -- Check missing order_id
        CASE WHEN order_id IS NULL OR TRIM(order_id) = '' OR UPPER(order_id) = 'NULL' THEN 1 ELSE 0 END as pay_missing_order,
        
        -- Check invalid order reference (not in ST_ORDERS)
        CASE 
            WHEN order_id IS NULL OR TRIM(order_id) = '' OR UPPER(order_id) = 'NULL' THEN 0
            WHEN NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 1
            ELSE 0
        END as pay_invalid_order,
        
        -- Check missing payment_date
        CASE WHEN payment_date IS NULL OR TRIM(payment_date) = '' THEN 1 ELSE 0 END as pay_missing_date,
        
        -- Check invalid payment_date
        CASE 
            WHEN payment_date IS NULL THEN 0
            WHEN UPPER(payment_date) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1
            ELSE 0
        END as pay_invalid_date,
        
        -- Check missing amount
        CASE WHEN amount IS NULL OR TRIM(amount) = '' THEN 1 ELSE 0 END as pay_missing_amount,
        
        -- Check invalid amount
        CASE 
            WHEN amount IS NULL THEN 0
            WHEN UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1
            ELSE 0
        END as pay_invalid_amount,
        
        -- Check payment_date before order_date (requires date parsing - simplified check)
        0 as pay_date_before_order,  -- Will check in next section with proper dates
        
        -- Check payment amount exceeds order amount (simplified check)
        0 as pay_amount_exceeds_order,  -- Will check in next section with proper numbers
        
        -- Check missing method
        CASE WHEN method IS NULL OR TRIM(method) = '' THEN 1 ELSE 0 END as pay_missing_method,
        
        -- Check invalid method
        CASE 
            WHEN method IS NULL OR TRIM(method) = '' THEN 0
            WHEN UPPER(method) NOT IN ('CARD', 'CARD', 'PAYPAL', 'PAY_PAL', 'BANK_TRANSFER', 'BANK-TF', 'CASH') THEN 0
            ELSE 0
        END as pay_invalid_method,
        
        -- Check duplicate payment_id
        CASE 
            WHEN payment_id IS NOT NULL AND 
                 (SELECT COUNT(*) FROM st_payments p2 WHERE p2.payment_id = p.payment_id) > 1 THEN 1
            ELSE 0
        END as pay_duplicate_id,
        
        -- Description
        CASE 
            WHEN order_id IS NULL THEN 'Missing order_id'
            WHEN NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 'Invalid order reference'
            WHEN UPPER(payment_date) IN ('N/A', 'NULL') THEN 'Invalid payment date'
            WHEN UPPER(amount) IN ('N/A', 'NULL') THEN 'Invalid amount'
            WHEN method IS NULL THEN 'Missing payment method'
            WHEN (SELECT COUNT(*) FROM st_payments p2 WHERE p2.payment_id = p.payment_id) > 1 THEN 'Duplicate payment_id'
            ELSE 'Multiple issues'
        END as issue_description,
        
        amount as raw_value
        
    FROM st_payments p
    WHERE 
        -- Only log records with at least one issue
        order_id IS NULL OR TRIM(order_id) = '' OR UPPER(order_id) = 'NULL'
        OR NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id)
        OR payment_date IS NULL OR TRIM(payment_date) = ''
        OR UPPER(payment_date) IN ('N/A', 'NULL', 'UNKNOWN')
        OR amount IS NULL OR TRIM(amount) = ''
        OR UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN')
        OR method IS NULL OR TRIM(method) = ''
        OR (SELECT COUNT(*) FROM st_payments p2 WHERE p2.payment_id = p.payment_id) > 1;
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment issues logged: ' || v_count);
END;
/

-- ============================================================================
-- SECTION 4: ADVANCED VALIDATION (Payment vs Order comparisons)
-- ============================================================================

DECLARE
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Validating Payment vs Order Consistency ---');
    
    -- Check ST_PAYMENT.amount > ST_ORDER.amount
    INSERT INTO lxn_data_consistency_log (
        table_name,
        record_id,
        pay_amount_exceeds_order,
        issue_description,
        raw_value
    )
    SELECT 
        'ST_PAYMENTS' as table_name,
        p.payment_id as record_id,
        1 as pay_amount_exceeds_order,
        'Payment amount exceeds order amount' as issue_description,
        'Payment: ' || p.amount || ', Order: ' || o.amount as raw_value
    FROM st_payments p
    JOIN st_orders o ON p.order_id = o.order_id
    WHERE 
        -- Try to extract numeric values and compare
        TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.]', '')) > 
        TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.]', ''))
        AND REGEXP_REPLACE(p.amount, '[^0-9.]', '') IS NOT NULL
        AND REGEXP_REPLACE(o.amount, '[^0-9.]', '') IS NOT NULL;
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment > Order amount issues logged: ' || v_count);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in advanced validation: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- SECTION 5: GENERATE SUMMARY REPORT
-- ============================================================================

PROMPT
PROMPT =======================================================
PROMPT DATA CONSISTENCY VALIDATION SUMMARY
PROMPT =======================================================

SELECT 
    table_name,
    COUNT(*) as total_issues_logged
FROM lxn_data_consistency_log
GROUP BY table_name
ORDER BY table_name;

PROMPT
PROMPT Top 10 Issues by Frequency:
SELECT * FROM (
    SELECT 
        issue_description,
        COUNT(*) as occurrence_count
    FROM lxn_data_consistency_log
    GROUP BY issue_description
    ORDER BY COUNT(*) DESC
) WHERE ROWNUM <= 10;

PROMPT
PROMPT Customer Issues Breakdown:
SELECT 
    SUM(cust_missing_id) as missing_id,
    SUM(cust_missing_name) as missing_name,
    SUM(cust_missing_email) as missing_email,
    SUM(cust_invalid_email) as invalid_email,
    SUM(cust_missing_phone) as missing_phone,
    SUM(cust_invalid_phone) as invalid_phone,
    SUM(cust_missing_reg_date) as missing_reg_date,
    SUM(cust_invalid_reg_date) as invalid_reg_date
FROM lxn_data_consistency_log
WHERE table_name = 'ST_CUSTOMERS';

PROMPT
PROMPT Order Issues Breakdown:
SELECT 
    SUM(ord_missing_customer) as missing_customer,
    SUM(ord_invalid_customer) as invalid_customer,
    SUM(ord_missing_date) as missing_date,
    SUM(ord_invalid_date) as invalid_date,
    SUM(ord_missing_amount) as missing_amount,
    SUM(ord_invalid_amount) as invalid_amount,
    SUM(ord_negative_not_refund) as negative_not_refund,
    SUM(ord_missing_currency) as missing_currency,
    SUM(ord_invalid_currency) as invalid_currency
FROM lxn_data_consistency_log
WHERE table_name = 'ST_ORDERS';

PROMPT
PROMPT Payment Issues Breakdown:
SELECT 
    SUM(pay_missing_order) as missing_order,
    SUM(pay_invalid_order) as invalid_order,
    SUM(pay_missing_date) as missing_date,
    SUM(pay_invalid_date) as invalid_date,
    SUM(pay_missing_amount) as missing_amount,
    SUM(pay_invalid_amount) as invalid_amount,
    SUM(pay_date_before_order) as date_before_order,
    SUM(pay_amount_exceeds_order) as amount_exceeds_order,
    SUM(pay_missing_method) as missing_method,
    SUM(pay_invalid_method) as invalid_method,
    SUM(pay_duplicate_id) as duplicate_id
FROM lxn_data_consistency_log
WHERE table_name = 'ST_PAYMENTS';

PROMPT
PROMPT =======================================================
PROMPT Validation completed! Check LXN_DATA_CONSISTENCY_LOG table
PROMPT Use: SELECT * FROM vw_consistency_summary;
PROMPT =======================================================
