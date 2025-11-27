-- ============================================================================
-- VALIDATE AND POPULATE LXN_DATA_CONSISTENCY_LOG
-- Scans ST_CUSTOMERS, ST_ORDERS, ST_PAYMENTS and logs data quality issues
-- NO TO_DATE CALLS - Uses regex validation instead to avoid ORA-01858 errors
-- ============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_customer_count    NUMBER := 0;
    v_order_count       NUMBER := 0;
    v_payment_count     NUMBER := 0;
    v_total_issues      NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('STARTING DATA CONSISTENCY VALIDATION');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Clear previous logs
    DELETE FROM lxn_data_consistency_log;
    COMMIT;

    -- ========================================================================
    -- VALIDATE ST_CUSTOMERS
    -- ========================================================================
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_CUSTOMERS ---');
    
    INSERT INTO lxn_data_consistency_log (
        source_table,
        record_id,
        cust_missing_id,
        cust_missing_name,
        cust_missing_email,
        cust_invalid_email,
        cust_missing_phone,
        cust_invalid_phone,
        cust_missing_reg_date,
        cust_invalid_reg_date,
        total_issues,
        severity,
        issue_description,
        raw_data_sample
    )
    SELECT 
        'ST_CUSTOMERS' as source_table,
        NVL(customer_id, 'NULL_ID') as record_id,
        
        -- Flag: Missing customer_id
        CASE WHEN customer_id IS NULL OR TRIM(customer_id) IS NULL THEN 1 ELSE 0 END as cust_missing_id,
        
        -- Flag: Missing full_name
        CASE WHEN full_name IS NULL OR TRIM(full_name) IS NULL THEN 1 ELSE 0 END as cust_missing_name,
        
        -- Flag: Missing email
        CASE WHEN email IS NULL OR TRIM(email) IS NULL THEN 1 ELSE 0 END as cust_missing_email,
        
        -- Flag: Invalid email format
        CASE WHEN email IS NOT NULL 
             AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') 
             THEN 1 ELSE 0 END as cust_invalid_email,
        
        -- Flag: Missing phone
        CASE WHEN phone IS NULL OR TRIM(phone) IS NULL THEN 1 ELSE 0 END as cust_missing_phone,
        
        -- Flag: Invalid phone (less than 7 digits)
        CASE WHEN phone IS NOT NULL 
             AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 
             THEN 1 ELSE 0 END as cust_invalid_phone,
        
        -- Flag: Missing reg_date
        CASE WHEN reg_date IS NULL OR TRIM(reg_date) IS NULL THEN 1 ELSE 0 END as cust_missing_reg_date,
        
        -- Flag: Invalid reg_date (not YYYY-MM-DD format)
        CASE WHEN reg_date IS NOT NULL 
             AND TRIM(reg_date) NOT IN ('', 'NULL', 'N/A', 'null')
             AND NOT REGEXP_LIKE(SUBSTR(reg_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
             THEN 1 ELSE 0 END as cust_invalid_reg_date,        -- Calculate total issues
        (CASE WHEN customer_id IS NULL OR TRIM(customer_id) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN full_name IS NULL OR TRIM(full_name) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN email IS NULL OR TRIM(email) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 1 ELSE 0 END +
         CASE WHEN phone IS NULL OR TRIM(phone) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN phone IS NOT NULL AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 THEN 1 ELSE 0 END +
         CASE WHEN reg_date IS NULL OR TRIM(reg_date) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN reg_date IS NOT NULL AND TRIM(reg_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(reg_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) as total_issues,
        
        -- Severity
        CASE 
            WHEN (CASE WHEN customer_id IS NULL OR TRIM(customer_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN full_name IS NULL OR TRIM(full_name) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN email IS NULL OR TRIM(email) IS NULL THEN 1 ELSE 0 END) >= 2 THEN 'CRITICAL'
            WHEN (CASE WHEN customer_id IS NULL OR TRIM(customer_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN full_name IS NULL OR TRIM(full_name) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN email IS NULL OR TRIM(email) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 1 ELSE 0 END +
                  CASE WHEN phone IS NULL OR TRIM(phone) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN phone IS NOT NULL AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 THEN 1 ELSE 0 END +
                  CASE WHEN reg_date IS NULL OR TRIM(reg_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN reg_date IS NOT NULL AND TRIM(reg_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(reg_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) >= 3 THEN 'HIGH'
            WHEN (CASE WHEN customer_id IS NULL OR TRIM(customer_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN full_name IS NULL OR TRIM(full_name) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN email IS NULL OR TRIM(email) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 1 ELSE 0 END +
                  CASE WHEN phone IS NULL OR TRIM(phone) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN phone IS NOT NULL AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 THEN 1 ELSE 0 END +
                  CASE WHEN reg_date IS NULL OR TRIM(reg_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN reg_date IS NOT NULL AND TRIM(reg_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(reg_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) >= 1 THEN 'MEDIUM'
            ELSE 'LOW'
        END as severity,
        
        'Customer record has data quality issues' as issue_description,
        SUBSTR('ID:' || customer_id || ' | Name:' || full_name || ' | Email:' || email || ' | Phone:' || phone, 1, 500) as raw_data_sample
    FROM st_customers
    WHERE 
        -- Only log records with at least one issue
        (customer_id IS NULL OR TRIM(customer_id) IS NULL) OR
        (full_name IS NULL OR TRIM(full_name) IS NULL) OR
        (email IS NULL OR TRIM(email) IS NULL) OR
        (email IS NOT NULL AND NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')) OR
        (phone IS NULL OR TRIM(phone) IS NULL) OR
        (phone IS NOT NULL AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7) OR
        (reg_date IS NULL OR TRIM(reg_date) IS NULL) OR
        (reg_date IS NOT NULL AND TRIM(reg_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(reg_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'));
    
    v_customer_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Customer issues logged: ' || v_customer_count);

    -- ========================================================================
    -- VALIDATE ST_ORDERS
    -- ========================================================================
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_ORDERS ---');
    
    INSERT INTO lxn_data_consistency_log (
        source_table,
        record_id,
        ord_missing_id,
        ord_missing_customer_id,
        ord_invalid_customer,
        ord_missing_amount,
        ord_invalid_amount,
        ord_negative_not_refund,
        ord_missing_currency,
        ord_invalid_currency,
        ord_missing_order_date,
        ord_invalid_order_date,
        total_issues,
        severity,
        issue_description,
        raw_data_sample
    )
    SELECT 
        'ST_ORDERS' as source_table,
        NVL(o.order_id, 'NULL_ID') as record_id,
        
        -- Flag: Missing order_id
        CASE WHEN o.order_id IS NULL OR TRIM(o.order_id) IS NULL THEN 1 ELSE 0 END as ord_missing_id,
        
        -- Flag: Missing customer_id
        CASE WHEN o.customer_id IS NULL OR TRIM(o.customer_id) IS NULL THEN 1 ELSE 0 END as ord_missing_customer_id,
        
        -- Flag: Invalid customer (customer doesn't exist in ST_CUSTOMERS)
        CASE WHEN o.customer_id IS NOT NULL 
             AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id)
             THEN 1 ELSE 0 END as ord_invalid_customer,
        
        -- Flag: Missing amount
        CASE WHEN o.amount IS NULL OR TRIM(o.amount) IS NULL THEN 1 ELSE 0 END as ord_missing_amount,
        
        -- Flag: Invalid amount (non-numeric or has text mixed in)
        CASE WHEN o.amount IS NOT NULL 
             AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
             AND (LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) = 0
                  OR UPPER(TRIM(o.amount)) = 'N/A'
                  OR UPPER(TRIM(o.amount)) = 'UNKNOWN')
             THEN 1 ELSE 0 END as ord_invalid_amount,
        
        -- Flag: Negative amount but currency not "REFUND"
        CASE WHEN o.amount IS NOT NULL 
             AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
             AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0
             AND REGEXP_REPLACE(o.amount, '[^0-9.-]', '') IS NOT NULL
             AND TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) < 0
             AND UPPER(NVL(o.currency, '')) != 'REFUND'
             THEN 1 ELSE 0 END as ord_negative_not_refund,
        
        -- Flag: Missing currency
        CASE WHEN o.currency IS NULL OR TRIM(o.currency) IS NULL THEN 1 ELSE 0 END as ord_missing_currency,
        
        -- Flag: Invalid currency (not in standard list)
        CASE WHEN o.currency IS NOT NULL 
             AND UPPER(o.currency) NOT IN ('USD', 'EUR', 'GBP', 'HUF', 'RON', 'REFUND', 'US$', 'EURO', '$', '€')
             THEN 1 ELSE 0 END as ord_invalid_currency,
        
        -- Flag: Missing order_date
        CASE WHEN o.order_date IS NULL OR TRIM(o.order_date) IS NULL THEN 1 ELSE 0 END as ord_missing_order_date,
        
        -- Flag: Invalid order_date (not YYYY-MM-DD format)
        CASE WHEN o.order_date IS NOT NULL 
             AND TRIM(o.order_date) NOT IN ('', 'NULL', 'N/A', 'null')
             AND NOT REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
             THEN 1 ELSE 0 END as ord_invalid_order_date,        -- Calculate total issues (adding missing ord_invalid_amount flag)
        (CASE WHEN o.order_id IS NULL OR TRIM(o.order_id) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN o.customer_id IS NULL OR TRIM(o.customer_id) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN o.customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 1 ELSE 0 END +
         CASE WHEN o.amount IS NULL OR TRIM(o.amount) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(o.amount)) = 'N/A' OR UPPER(TRIM(o.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
         CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(o.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) < 0 AND UPPER(NVL(o.currency, '')) != 'REFUND' THEN 1 ELSE 0 END +
         CASE WHEN o.currency IS NULL OR TRIM(o.currency) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN o.currency IS NOT NULL AND UPPER(o.currency) NOT IN ('USD', 'EUR', 'GBP', 'HUF', 'RON', 'REFUND', 'US$', 'EURO', '$', '€') THEN 1 ELSE 0 END +
         CASE WHEN o.order_date IS NULL OR TRIM(o.order_date) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN o.order_date IS NOT NULL AND TRIM(o.order_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) as total_issues,
        
        -- Severity
        CASE 
            WHEN (CASE WHEN o.order_id IS NULL OR TRIM(o.order_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.customer_id IS NULL OR TRIM(o.customer_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NULL OR TRIM(o.amount) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(o.amount)) = 'N/A' OR UPPER(TRIM(o.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(o.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) < 0 AND UPPER(NVL(o.currency, '')) != 'REFUND' THEN 1 ELSE 0 END +
                  CASE WHEN o.currency IS NULL OR TRIM(o.currency) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.currency IS NOT NULL AND UPPER(o.currency) NOT IN ('USD', 'EUR', 'GBP', 'HUF', 'RON', 'REFUND', 'US$', 'EURO', '$', '€') THEN 1 ELSE 0 END +
                  CASE WHEN o.order_date IS NULL OR TRIM(o.order_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.order_date IS NOT NULL AND TRIM(o.order_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) >= 4 THEN 'CRITICAL'
            WHEN (CASE WHEN o.order_id IS NULL OR TRIM(o.order_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.customer_id IS NULL OR TRIM(o.customer_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NULL OR TRIM(o.amount) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(o.amount)) = 'N/A' OR UPPER(TRIM(o.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
                  CASE WHEN o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(o.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) < 0 AND UPPER(NVL(o.currency, '')) != 'REFUND' THEN 1 ELSE 0 END +
                  CASE WHEN o.currency IS NULL OR TRIM(o.currency) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.currency IS NOT NULL AND UPPER(o.currency) NOT IN ('USD', 'EUR', 'GBP', 'HUF', 'RON', 'REFUND', 'US$', 'EURO', '$', '€') THEN 1 ELSE 0 END +
                  CASE WHEN o.order_date IS NULL OR TRIM(o.order_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN o.order_date IS NOT NULL AND TRIM(o.order_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END) >= 2 THEN 'HIGH'
            ELSE 'MEDIUM'
        END as severity,
        
        'Order record has data quality issues' as issue_description,
        SUBSTR('OrderID:' || o.order_id || ' | CustID:' || o.customer_id || ' | Amount:' || o.amount || ' | Currency:' || o.currency, 1, 500) as raw_data_sample
    FROM st_orders o
    WHERE 
        -- Only log records with at least one issue
        (o.order_id IS NULL OR TRIM(o.order_id) IS NULL) OR
        (o.customer_id IS NULL OR TRIM(o.customer_id) IS NULL) OR
        (o.customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id)) OR
        (o.amount IS NULL OR TRIM(o.amount) IS NULL) OR
        (o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(o.amount)) = 'N/A' OR UPPER(TRIM(o.amount)) = 'UNKNOWN')) OR
        (o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(o.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) < 0 AND UPPER(NVL(o.currency, '')) != 'REFUND') OR
        (o.currency IS NULL OR TRIM(o.currency) IS NULL) OR
        (o.currency IS NOT NULL AND UPPER(o.currency) NOT IN ('USD', 'EUR', 'GBP', 'HUF', 'RON', 'REFUND', 'US$', 'EURO', '$', '€')) OR
        (o.order_date IS NULL OR TRIM(o.order_date) IS NULL) OR
        (o.order_date IS NOT NULL AND TRIM(o.order_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'));
    
    v_order_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order issues logged: ' || v_order_count);

    -- ========================================================================
    -- VALIDATE ST_PAYMENTS
    -- ========================================================================
    DBMS_OUTPUT.PUT_LINE('--- Validating ST_PAYMENTS ---');
    
    INSERT INTO lxn_data_consistency_log (
        source_table,
        record_id,
        pay_missing_id,
        pay_missing_order_id,
        pay_invalid_order,
        pay_missing_amount,
        pay_invalid_amount,
        pay_negative_amount,
        pay_amount_exceeds_order,
        pay_missing_payment_date,
        pay_invalid_payment_date,
        pay_date_before_order,
        pay_missing_method,
        pay_invalid_method,
        total_issues,
        severity,
        issue_description,
        raw_data_sample
    )
    SELECT 
        'ST_PAYMENTS' as source_table,
        NVL(p.payment_id, 'NULL_ID') as record_id,
        
        -- Flag: Missing payment_id
        CASE WHEN p.payment_id IS NULL OR TRIM(p.payment_id) IS NULL THEN 1 ELSE 0 END as pay_missing_id,
        
        -- Flag: Missing order_id
        CASE WHEN p.order_id IS NULL OR TRIM(p.order_id) IS NULL THEN 1 ELSE 0 END as pay_missing_order_id,
        
        -- Flag: Invalid order (order doesn't exist in ST_ORDERS)
        CASE WHEN p.order_id IS NOT NULL 
             AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id)
             THEN 1 ELSE 0 END as pay_invalid_order,
        
        -- Flag: Missing amount
        CASE WHEN p.amount IS NULL OR TRIM(p.amount) IS NULL THEN 1 ELSE 0 END as pay_missing_amount,
        
        -- Flag: Invalid amount (non-numeric or has text mixed in)
        CASE WHEN p.amount IS NOT NULL 
             AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
             AND (LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) = 0
                  OR UPPER(TRIM(p.amount)) = 'N/A'
                  OR UPPER(TRIM(p.amount)) = 'UNKNOWN')
             THEN 1 ELSE 0 END as pay_invalid_amount,
        
        -- Flag: Negative payment amount
        CASE WHEN p.amount IS NOT NULL 
             AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
             AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0
             AND REGEXP_REPLACE(p.amount, '[^0-9.-]', '') IS NOT NULL
             AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) < 0
             THEN 1 ELSE 0 END as pay_negative_amount,
        
        -- Flag: Payment amount exceeds order amount
        CASE WHEN p.amount IS NOT NULL AND p.order_id IS NOT NULL
             AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
             AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0
             AND EXISTS (
                 SELECT 1 FROM st_orders o 
                 WHERE o.order_id = p.order_id
                 AND o.amount IS NOT NULL
                 AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown')
                 AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0
                 AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', ''))
             )
             THEN 1 ELSE 0 END as pay_amount_exceeds_order,
        
        -- Flag: Missing payment_date
        CASE WHEN p.payment_date IS NULL OR TRIM(p.payment_date) IS NULL THEN 1 ELSE 0 END as pay_missing_payment_date,
        
        -- Flag: Invalid payment_date (not YYYY-MM-DD format)
        CASE WHEN p.payment_date IS NOT NULL 
             AND TRIM(p.payment_date) NOT IN ('', 'NULL', 'N/A', 'null')
             AND NOT REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
             THEN 1 ELSE 0 END as pay_invalid_payment_date,        -- Flag: Payment date before order date (string comparison)
        CASE WHEN p.payment_date IS NOT NULL AND p.order_id IS NOT NULL
             AND REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
             AND EXISTS (
                 SELECT 1 FROM st_orders o 
                 WHERE o.order_id = p.order_id
                 AND REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
                 AND SUBSTR(p.payment_date, 1, 10) < SUBSTR(o.order_date, 1, 10)
             )
             THEN 1 ELSE 0 END as pay_date_before_order,
        
        -- Flag: Missing method
        CASE WHEN p.method IS NULL OR TRIM(p.method) IS NULL THEN 1 ELSE 0 END as pay_missing_method,
        
        -- Flag: Invalid payment method
        CASE WHEN p.method IS NOT NULL 
             AND UPPER(p.method) NOT IN ('CARD', 'CREDIT CARD', 'DEBIT CARD', 'PAYPAL', 'BANK TRANSFER', 'WIRE', 'CASH', 'CHECK')
             THEN 1 ELSE 0 END as pay_invalid_method,
        
        -- Calculate total issues
        (CASE WHEN p.payment_id IS NULL OR TRIM(p.payment_id) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN p.order_id IS NULL OR TRIM(p.order_id) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN p.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 1 ELSE 0 END +
         CASE WHEN p.amount IS NULL OR TRIM(p.amount) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(p.amount)) = 'N/A' OR UPPER(TRIM(p.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
         CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(p.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) < 0 THEN 1 ELSE 0 END +
         CASE WHEN p.amount IS NOT NULL AND p.order_id IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', ''))) THEN 1 ELSE 0 END +
         CASE WHEN p.payment_date IS NULL OR TRIM(p.payment_date) IS NULL THEN 1 ELSE 0 END +
         CASE WHEN p.payment_date IS NOT NULL AND TRIM(p.payment_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END +
         CASE WHEN p.payment_date IS NOT NULL AND p.order_id IS NOT NULL AND REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND SUBSTR(p.payment_date, 1, 10) < SUBSTR(o.order_date, 1, 10)) THEN 1 ELSE 0 END +
         CASE WHEN p.method IS NULL OR TRIM(p.method) IS NULL THEN 1 ELSE 0 END) as total_issues,
        
        -- Severity
        CASE 
            WHEN (CASE WHEN p.payment_id IS NULL OR TRIM(p.payment_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.order_id IS NULL OR TRIM(p.order_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NULL OR TRIM(p.amount) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(p.amount)) = 'N/A' OR UPPER(TRIM(p.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(p.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) < 0 THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND p.order_id IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', ''))) THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NULL OR TRIM(p.payment_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NOT NULL AND TRIM(p.payment_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NOT NULL AND p.order_id IS NOT NULL AND REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND SUBSTR(p.payment_date, 1, 10) < SUBSTR(o.order_date, 1, 10)) THEN 1 ELSE 0 END +
                  CASE WHEN p.method IS NULL OR TRIM(p.method) IS NULL THEN 1 ELSE 0 END) >= 4 THEN 'CRITICAL'
            WHEN (CASE WHEN p.payment_id IS NULL OR TRIM(p.payment_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.order_id IS NULL OR TRIM(p.order_id) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NULL OR TRIM(p.amount) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(p.amount)) = 'N/A' OR UPPER(TRIM(p.amount)) = 'UNKNOWN') THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(p.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) < 0 THEN 1 ELSE 0 END +
                  CASE WHEN p.amount IS NOT NULL AND p.order_id IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', ''))) THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NULL OR TRIM(p.payment_date) IS NULL THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NOT NULL AND TRIM(p.payment_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') THEN 1 ELSE 0 END +
                  CASE WHEN p.payment_date IS NOT NULL AND p.order_id IS NOT NULL AND REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND SUBSTR(p.payment_date, 1, 10) < SUBSTR(o.order_date, 1, 10)) THEN 1 ELSE 0 END +
                  CASE WHEN p.method IS NULL OR TRIM(p.method) IS NULL THEN 1 ELSE 0 END) >= 2 THEN 'HIGH'
            ELSE 'MEDIUM'
        END as severity,

        'Payment record has data quality issues' as issue_description,
        SUBSTR('PaymentID:' || p.payment_id || ' | OrderID:' || p.order_id || ' | Amount:' || p.amount || ' | Method:' || p.method, 1, 500) as raw_data_sample
    FROM st_payments p
    WHERE 
        -- Only log records with at least one issue
        (p.payment_id IS NULL OR TRIM(p.payment_id) IS NULL) OR
        (p.order_id IS NULL OR TRIM(p.order_id) IS NULL) OR
        (p.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id)) OR
        (p.amount IS NULL OR TRIM(p.amount) IS NULL) OR
        (p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND (LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) = 0 OR UPPER(TRIM(p.amount)) = 'N/A' OR UPPER(TRIM(p.amount)) = 'UNKNOWN')) OR
        (p.amount IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND REGEXP_REPLACE(p.amount, '[^0-9.-]', '') IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) < 0) OR
        (p.amount IS NOT NULL AND p.order_id IS NOT NULL AND TRIM(p.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > 0 AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND o.amount IS NOT NULL AND TRIM(o.amount) NOT IN ('', 'NULL', 'N/A', 'null', 'unknown') AND LENGTH(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')) > 0 AND TO_NUMBER(REGEXP_REPLACE(p.amount, '[^0-9.-]', '')) > TO_NUMBER(REGEXP_REPLACE(o.amount, '[^0-9.-]', '')))) OR
        (p.payment_date IS NULL OR TRIM(p.payment_date) IS NULL) OR
        (p.payment_date IS NOT NULL AND TRIM(p.payment_date) NOT IN ('', 'NULL', 'N/A', 'null') AND NOT REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')) OR
        (p.payment_date IS NOT NULL AND p.order_id IS NOT NULL AND REGEXP_LIKE(SUBSTR(p.payment_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id AND REGEXP_LIKE(SUBSTR(o.order_date, 1, 10), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND SUBSTR(p.payment_date, 1, 10) < SUBSTR(o.order_date, 1, 10))) OR
        (p.method IS NULL OR TRIM(p.method) IS NULL);
    
    v_payment_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Payment issues logged: ' || v_payment_count);

    -- ========================================================================
    -- SUMMARY
    -- ========================================================================
    v_total_issues := v_customer_count + v_order_count + v_payment_count;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('VALIDATION COMPLETED');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Total records with issues: ' || v_total_issues);
    DBMS_OUTPUT.PUT_LINE('  - Customer issues: ' || v_customer_count);
    DBMS_OUTPUT.PUT_LINE('  - Order issues: ' || v_order_count);
    DBMS_OUTPUT.PUT_LINE('  - Payment issues: ' || v_payment_count);
    DBMS_OUTPUT.PUT_LINE('========================================');
END;
/

-- ============================================================================
-- QUERY THE RESULTS
-- ============================================================================

-- Summary by source table
SELECT 
    source_table,
    severity,
    COUNT(*) as issue_count,
    ROUND(AVG(total_issues), 2) as avg_issues_per_record
FROM lxn_data_consistency_log
GROUP BY source_table, severity
ORDER BY source_table, 
    CASE severity 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END;

-- Most common issues
SELECT * FROM (
    SELECT 'Customer Issues' as category, COUNT(*) as total FROM lxn_data_consistency_log WHERE cust_missing_id = 1 UNION ALL
    SELECT 'Customer Issues', COUNT(*) FROM lxn_data_consistency_log WHERE cust_invalid_email = 1 UNION ALL
    SELECT 'Order Issues', COUNT(*) FROM lxn_data_consistency_log WHERE ord_negative_not_refund = 1 UNION ALL
    SELECT 'Order Issues', COUNT(*) FROM lxn_data_consistency_log WHERE ord_invalid_customer = 1 UNION ALL
    SELECT 'Payment Issues', COUNT(*) FROM lxn_data_consistency_log WHERE pay_amount_exceeds_order = 1 UNION ALL
    SELECT 'Payment Issues', COUNT(*) FROM lxn_data_consistency_log WHERE pay_date_before_order = 1
)
ORDER BY total DESC;

-- Sample of critical issues
SELECT 
    source_table,
    record_id,
    total_issues,
    issue_description,
    raw_data_sample
FROM lxn_data_consistency_log
WHERE severity = 'CRITICAL'
ORDER BY total_issues DESC
FETCH FIRST 10 ROWS ONLY;

COMMIT;
