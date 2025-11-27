-- ============================================================================
-- DATA QUALITY MASTER PACKAGE
-- Combines all data cleansing and validation procedures
-- Run this ONCE after running the original setup scripts
-- ============================================================================

SET SERVEROUTPUT ON;

-- ============================================================================
-- CREATE PACKAGE SPECIFICATION
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_data_quality AS
    -- Main procedures (callable by judges/reviewers)
    PROCEDURE run_full_cleansing;
    PROCEDURE run_validation_only;
    PROCEDURE run_cleansing_only;
    PROCEDURE show_quality_report;
    
    -- Individual step procedures
    PROCEDURE step1_validate_consistency;
    PROCEDURE step2_cleanse_customers;
    PROCEDURE step3_cleanse_orders;
    PROCEDURE step4_cleanse_payments;
    PROCEDURE step5_generate_report;
END pkg_data_quality;
/

-- ============================================================================
-- CREATE PACKAGE BODY
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY pkg_data_quality AS

    -- ========================================================================
    -- MAIN PROCEDURE: Run Complete Data Cleansing Pipeline
    -- ========================================================================
    PROCEDURE run_full_cleansing AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('FULL DATA CLEANSING PIPELINE STARTED');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Step 1: Validate raw data
        step1_validate_consistency;
        
        -- Step 2: Cleanse customers
        step2_cleanse_customers;
        
        -- Step 3: Cleanse orders
        step3_cleanse_orders;
        
        -- Step 4: Cleanse payments
        step4_cleanse_payments;
        
        -- Step 5: Generate report
        step5_generate_report;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('FULL DATA CLEANSING COMPLETED SUCCESSFULLY!');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('Next: Query cleaned tables (dw_customers, dw_orders, dw_payments)');
        DBMS_OUTPUT.PUT_LINE('View: SELECT * FROM vw_consistency_summary;');
    END run_full_cleansing;

    -- ========================================================================
    -- VALIDATION ONLY
    -- ========================================================================
    PROCEDURE run_validation_only AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Running validation only...');
        step1_validate_consistency;
        DBMS_OUTPUT.PUT_LINE('Validation completed. Check LXN_DATA_CONSISTENCY_LOG table.');
    END run_validation_only;

    -- ========================================================================
    -- CLEANSING ONLY (skip validation)
    -- ========================================================================
    PROCEDURE run_cleansing_only AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Running cleansing only...');
        step2_cleanse_customers;
        step3_cleanse_orders;
        step4_cleanse_payments;
        DBMS_OUTPUT.PUT_LINE('Cleansing completed. Check dw_* tables.');
    END run_cleansing_only;

    -- ========================================================================
    -- SHOW QUALITY REPORT
    -- ========================================================================
    PROCEDURE show_quality_report AS
    BEGIN
        step5_generate_report;
    END show_quality_report;

    -- ========================================================================
    -- STEP 1: VALIDATE CONSISTENCY
    -- ========================================================================
    PROCEDURE step1_validate_consistency AS
        v_count NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 1: Validating Data Consistency ---');
        
        -- Clear previous log
        DELETE FROM lxn_data_consistency_log;
        COMMIT;
        
        -- Validate ST_CUSTOMERS
        INSERT INTO lxn_data_consistency_log (
            table_name, record_id,
            cust_missing_id, cust_missing_name, cust_missing_email, cust_invalid_email,
            cust_missing_phone, cust_invalid_phone, cust_missing_reg_date, cust_invalid_reg_date,
            issue_description
        )
        SELECT 
            'ST_CUSTOMERS', NVL(customer_id, 'NULL_' || ROWNUM),
            CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' THEN 1 ELSE 0 END,
            CASE WHEN full_name IS NULL OR TRIM(full_name) = '' THEN 1 ELSE 0 END,
            CASE WHEN email IS NULL OR TRIM(email) = '' THEN 1 ELSE 0 END,
            CASE WHEN email IS NOT NULL AND (UPPER(email) = 'NOT-AN-EMAIL' OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')) THEN 1 ELSE 0 END,
            CASE WHEN phone IS NULL OR TRIM(phone) = '' THEN 1 ELSE 0 END,
            CASE WHEN phone IS NOT NULL AND (LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7 OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) > 15) THEN 1 ELSE 0 END,
            CASE WHEN reg_date IS NULL OR TRIM(reg_date) = '' THEN 1 ELSE 0 END,
            CASE WHEN reg_date IS NOT NULL AND UPPER(reg_date) IN ('UNKNOWN', 'N/A', 'NULL') THEN 1 ELSE 0 END,
            'Customer data issue'
        FROM st_customers
        WHERE customer_id IS NULL OR full_name IS NULL OR email IS NULL 
           OR UPPER(email) = 'NOT-AN-EMAIL' OR NOT REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
           OR phone IS NULL OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 7;
        
        v_count := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('  Customer issues logged: ' || v_count);
        
        -- Validate ST_ORDERS
        INSERT INTO lxn_data_consistency_log (
            table_name, record_id,
            ord_missing_customer, ord_invalid_customer, ord_missing_date, ord_invalid_date,
            ord_missing_amount, ord_invalid_amount, ord_negative_not_refund,
            ord_missing_currency, ord_invalid_currency,
            issue_description
        )
        SELECT 
            'ST_ORDERS', NVL(order_id, 'NULL_' || ROWNUM),
            CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' OR UPPER(customer_id) = 'NULL' THEN 1 ELSE 0 END,
            CASE WHEN customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id) THEN 1 ELSE 0 END,
            CASE WHEN order_date IS NULL OR TRIM(order_date) = '' THEN 1 ELSE 0 END,
            CASE WHEN order_date IS NOT NULL AND UPPER(order_date) IN ('UNKNOWN', 'N/A', 'NULL', 'TODAY', 'YESTERDAY') THEN 1 ELSE 0 END,
            CASE WHEN amount IS NULL OR TRIM(amount) = '' THEN 1 ELSE 0 END,
            CASE WHEN amount IS NOT NULL AND UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1 ELSE 0 END,
            CASE WHEN amount IS NOT NULL AND TO_NUMBER(REGEXP_REPLACE(amount, '[^0-9.-]', '')) < 0 AND UPPER(NVL(currency, '')) NOT LIKE '%REFUND%' THEN 1 ELSE 0 END,
            CASE WHEN currency IS NULL OR TRIM(currency) = '' THEN 1 ELSE 0 END,
            CASE WHEN currency IS NOT NULL AND UPPER(currency) NOT IN ('USD', 'US$', 'EUR', 'EURO', 'HUF', 'REFUND') THEN 1 ELSE 0 END,
            'Order data issue'
        FROM st_orders o
        WHERE customer_id IS NULL OR UPPER(customer_id) = 'NULL'
           OR NOT EXISTS (SELECT 1 FROM st_customers c WHERE c.customer_id = o.customer_id)
           OR order_date IS NULL OR UPPER(order_date) IN ('UNKNOWN', 'N/A')
           OR amount IS NULL OR UPPER(amount) IN ('N/A', 'NULL')
           OR currency IS NULL;
        
        v_count := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('  Order issues logged: ' || v_count);
        
        -- Validate ST_PAYMENTS
        INSERT INTO lxn_data_consistency_log (
            table_name, record_id,
            pay_missing_order, pay_invalid_order, pay_missing_date, pay_invalid_date,
            pay_missing_amount, pay_invalid_amount, pay_missing_method, pay_duplicate_id,
            issue_description
        )
        SELECT 
            'ST_PAYMENTS', NVL(payment_id, 'NULL_' || ROWNUM),
            CASE WHEN order_id IS NULL OR TRIM(order_id) = '' OR UPPER(order_id) = 'NULL' THEN 1 ELSE 0 END,
            CASE WHEN order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id) THEN 1 ELSE 0 END,
            CASE WHEN payment_date IS NULL OR TRIM(payment_date) = '' THEN 1 ELSE 0 END,
            CASE WHEN payment_date IS NOT NULL AND UPPER(payment_date) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1 ELSE 0 END,
            CASE WHEN amount IS NULL OR TRIM(amount) = '' THEN 1 ELSE 0 END,
            CASE WHEN amount IS NOT NULL AND UPPER(amount) IN ('N/A', 'NULL', 'UNKNOWN') THEN 1 ELSE 0 END,
            CASE WHEN method IS NULL OR TRIM(method) = '' THEN 1 ELSE 0 END,
            CASE WHEN payment_id IS NOT NULL AND (SELECT COUNT(*) FROM st_payments p2 WHERE p2.payment_id = p.payment_id) > 1 THEN 1 ELSE 0 END,
            'Payment data issue'
        FROM st_payments p
        WHERE order_id IS NULL OR UPPER(order_id) = 'NULL'
           OR NOT EXISTS (SELECT 1 FROM st_orders o WHERE o.order_id = p.order_id)
           OR payment_date IS NULL OR UPPER(payment_date) IN ('N/A', 'NULL')
           OR amount IS NULL OR UPPER(amount) IN ('N/A', 'NULL')
           OR method IS NULL;
        
        v_count := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('  Payment issues logged: ' || v_count);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Validation completed!');
    END step1_validate_consistency;

    -- ========================================================================
    -- STEP 2: CLEANSE CUSTOMERS
    -- ========================================================================
    PROCEDURE step2_cleanse_customers AS
        v_count NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 2: Cleansing Customer Data ---');
        
        -- Clear existing data (disable constraints temporarily)
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE dw_orders DISABLE CONSTRAINT fk_orders_customer';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dw_customers';
        COMMIT;
        
        -- Insert cleansed data
        INSERT INTO dw_customers (
            customer_id, customer_id_raw, first_name, last_name, full_name,
            email, email_valid, phone, phone_cleaned, reg_date, reg_date_raw
        )
        SELECT 
            extract_numeric_id(customer_id),
            customer_id,
            CASE WHEN INSTR(full_name, '/') > 0 THEN TRIM(SUBSTR(full_name, 1, INSTR(full_name, '/') - 1))
                 WHEN INSTR(full_name, ' ') > 0 THEN TRIM(SUBSTR(full_name, 1, INSTR(full_name, ' ') - 1))
                 ELSE TRIM(full_name) END,
            CASE WHEN INSTR(full_name, '/') > 0 THEN TRIM(SUBSTR(full_name, INSTR(full_name, '/') + 1))
                 WHEN INSTR(full_name, ' ') > 0 THEN TRIM(SUBSTR(full_name, INSTR(full_name, ' ') + 1))
                 ELSE NULL END,
            REPLACE(full_name, '/', ' '),
            CASE WHEN UPPER(email) = 'NOT-AN-EMAIL' THEN NULL
                 WHEN INSTR(email, ',') > 0 THEN LOWER(TRIM(SUBSTR(email, 1, INSTR(email, ',') - 1)))
                 ELSE LOWER(TRIM(email)) END,
            is_valid_email(email),
            phone,
            clean_phone(phone),
            parse_date_multi(reg_date),
            reg_date
        FROM st_customers
        WHERE customer_id IS NOT NULL;
        
        v_count := SQL%ROWCOUNT;
        COMMIT;
        
        -- Re-enable constraints
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE dw_orders ENABLE CONSTRAINT fk_orders_customer';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        
        DBMS_OUTPUT.PUT_LINE('  Customers cleansed: ' || v_count);
    END step2_cleanse_customers;

    -- ========================================================================
    -- STEP 3: CLEANSE ORDERS
    -- ========================================================================
    PROCEDURE step3_cleanse_orders AS
        v_count NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 3: Cleansing Order Data ---');
        
        -- Clear existing data
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE dw_payments DISABLE CONSTRAINT fk_payments_order';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dw_orders';
        COMMIT;
        
        INSERT INTO dw_orders (
            order_id, customer_id, customer_id_raw, customer_valid,
            order_date, order_date_raw, amount, amount_raw,
            currency, currency_raw, is_refund
        )
        SELECT 
            o.order_id,
            c.customer_id,
            o.customer_id,
            CASE WHEN c.customer_id IS NOT NULL THEN 1 ELSE 0 END,
            parse_date_multi(o.order_date),
            o.order_date,
            ABS(clean_amount(o.amount)),
            o.amount,
            COALESCE(cm.clean_currency, 
                CASE WHEN UPPER(o.currency) LIKE '%USD%' THEN 'USD'
                     WHEN UPPER(o.currency) LIKE '%EUR%' THEN 'EUR'
                     WHEN UPPER(o.currency) = 'HUF' THEN 'HUF' END),
            o.currency,
            CASE WHEN clean_amount(o.amount) < 0 THEN 1 ELSE 0 END
        FROM st_orders o
        LEFT JOIN currency_mapping cm ON UPPER(TRIM(o.currency)) = cm.raw_currency
        LEFT JOIN dw_customers c ON o.customer_id = c.customer_id_raw
        WHERE o.order_id IS NOT NULL;
        
        v_count := SQL%ROWCOUNT;
        COMMIT;
        
        -- Re-enable constraints
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE dw_payments ENABLE CONSTRAINT fk_payments_order';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        
        DBMS_OUTPUT.PUT_LINE('  Orders cleansed: ' || v_count);
    END step3_cleanse_orders;

    -- ========================================================================
    -- STEP 4: CLEANSE PAYMENTS
    -- ========================================================================
    PROCEDURE step4_cleanse_payments AS
        v_count NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 4: Cleansing Payment Data ---');
        
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dw_payments';
        
        INSERT INTO dw_payments (
            payment_id, order_id, order_valid,
            payment_date, payment_date_raw,
            amount, amount_raw, method, method_raw, is_duplicate
        )
        SELECT 
            p.payment_id,
            CASE WHEN UPPER(p.order_id) = 'NULL' OR p.order_id = '' THEN NULL ELSE p.order_id END,
            CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE 0 END,
            parse_date_multi(p.payment_date),
            p.payment_date,
            ABS(clean_amount(p.amount)),
            p.amount,
            COALESCE(pmm.clean_method,
                CASE WHEN UPPER(p.method) LIKE '%CARD%' THEN 'Card'
                     WHEN UPPER(p.method) LIKE '%PAYPAL%' THEN 'PayPal'
                     WHEN UPPER(p.method) LIKE '%BANK%' THEN 'Bank Transfer'
                     WHEN UPPER(p.method) = 'CASH' THEN 'Cash' END),
            p.method,
            0
        FROM st_payments p
        LEFT JOIN payment_method_mapping pmm ON TRIM(p.method) = pmm.raw_method
        LEFT JOIN dw_orders o ON p.order_id = o.order_id
        WHERE p.payment_id IS NOT NULL;
        
        v_count := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('  Payments cleansed: ' || v_count);
    END step4_cleanse_payments;

    -- ========================================================================
    -- STEP 5: GENERATE QUALITY REPORT
    -- ========================================================================
    PROCEDURE step5_generate_report AS
        v_total_cust NUMBER;
        v_total_ord NUMBER;
        v_total_pay NUMBER;
        v_issues NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- STEP 5: Data Quality Report ---');
        
        SELECT COUNT(*) INTO v_total_cust FROM dw_customers;
        SELECT COUNT(*) INTO v_total_ord FROM dw_orders;
        SELECT COUNT(*) INTO v_total_pay FROM dw_payments;
        SELECT COUNT(*) INTO v_issues FROM lxn_data_consistency_log;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('DATA QUALITY SUMMARY');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('Cleaned Records:');
        DBMS_OUTPUT.PUT_LINE('  - Customers: ' || v_total_cust);
        DBMS_OUTPUT.PUT_LINE('  - Orders: ' || v_total_ord);
        DBMS_OUTPUT.PUT_LINE('  - Payments: ' || v_total_pay);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Data Issues Logged: ' || v_issues);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('View detailed report:');
        DBMS_OUTPUT.PUT_LINE('  SELECT * FROM vw_consistency_summary;');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
    END step5_generate_report;

END pkg_data_quality;
/

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Package PKG_DATA_QUALITY created successfully!' as status FROM DUAL;
SELECT 'Available procedures:' as info FROM DUAL;
SELECT '  - EXEC pkg_data_quality.run_full_cleansing;' as procedure FROM DUAL
UNION ALL
SELECT '  - EXEC pkg_data_quality.run_validation_only;' FROM DUAL
UNION ALL
SELECT '  - EXEC pkg_data_quality.run_cleansing_only;' FROM DUAL
UNION ALL
SELECT '  - EXEC pkg_data_quality.show_quality_report;' FROM DUAL;
