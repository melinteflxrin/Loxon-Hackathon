-- ============================================================================
-- PAYMENT DATA CLEANSING SCRIPT
-- Cleans ST_PAYMENTS into DW_PAYMENTS
-- Run after: 03_cleanse_orders.sql
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('PAYMENT DATA CLEANSING STARTED');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- ============================================================================
-- STEP 1: INSERT AND CLEAN PAYMENT DATA
-- ============================================================================

INSERT INTO dw_payments (
    payment_id,
    order_id,
    order_valid,
    payment_date,
    payment_date_raw,
    amount,
    amount_raw,
    method,
    method_raw,
    is_duplicate
)
SELECT 
    p.payment_id,
    
    -- Link to order
    CASE 
        WHEN UPPER(p.order_id) = 'NULL' OR p.order_id = '' THEN NULL
        ELSE p.order_id
    END as order_id,
    
    -- Mark if order reference is valid
    CASE 
        WHEN o.order_id IS NOT NULL THEN 1
        WHEN p.order_id IS NULL OR UPPER(p.order_id) = 'NULL' OR p.order_id = '' THEN 0
        ELSE 0
    END as order_valid,
    
    -- Parse payment date
    parse_date_multi(p.payment_date) as payment_date,
    p.payment_date as payment_date_raw,
    
    -- Clean amount (take absolute value)
    ABS(clean_amount(p.amount)) as amount,
    p.amount as amount_raw,
    
    -- Normalize payment method using mapping table
    COALESCE(
        pmm.clean_method,
        CASE
            WHEN UPPER(p.method) LIKE '%CARD%' THEN 'Card'
            WHEN UPPER(p.method) LIKE '%PAYPAL%' OR UPPER(p.method) LIKE '%PAY_PAL%' THEN 'PayPal'
            WHEN UPPER(p.method) LIKE '%BANK%' OR UPPER(p.method) LIKE '%TRANSFER%' THEN 'Bank Transfer'
            WHEN UPPER(p.method) = 'CASH' THEN 'Cash'
            ELSE NULL
        END
    ) as method,
    p.method as method_raw,
    
    -- Mark duplicates (will be updated in next step)
    0 as is_duplicate
    
FROM st_payments p
LEFT JOIN payment_method_mapping pmm ON TRIM(p.method) = pmm.raw_method
LEFT JOIN dw_orders o ON p.order_id = o.order_id
WHERE p.payment_id IS NOT NULL;

COMMIT;

-- ============================================================================
-- STEP 2: DETECT AND MARK DUPLICATE PAYMENTS
-- ============================================================================

DECLARE
    v_dup_count NUMBER;
BEGIN
    -- Update is_duplicate flag for duplicate payment_ids
    UPDATE dw_payments
    SET is_duplicate = 1
    WHERE payment_id IN (
        SELECT payment_id
        FROM (
            SELECT payment_id, COUNT(*) as cnt
            FROM dw_payments
            GROUP BY payment_id
            HAVING COUNT(*) > 1
        )
    );
    
    v_dup_count := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Duplicate payment IDs flagged: ' || v_dup_count);
    
    -- Show duplicate details
    IF v_dup_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Duplicate payment IDs (showing first 10):');
        FOR rec IN (
            SELECT payment_id, COUNT(*) as occurrences
            FROM dw_payments
            WHERE is_duplicate = 1
            GROUP BY payment_id
            ORDER BY COUNT(*) DESC
            FETCH FIRST 10 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || rec.payment_id || ': ' || rec.occurrences || ' occurrences');
        END LOOP;
    END IF;
END;
/

-- ============================================================================
-- STEP 3: HANDLE DUPLICATE PAYMENT_IDs (KEEP BEST RECORD)
-- ============================================================================

-- For duplicate payment_ids, keep the one with:
-- 1. Valid order reference
-- 2. Most recent payment date
-- 3. Non-null amount
-- Delete others

DECLARE
    v_deleted NUMBER := 0;
BEGIN
    DELETE FROM dw_payments
    WHERE ROWID IN (
        SELECT rid FROM (
            SELECT 
                ROWID as rid,
                ROW_NUMBER() OVER (
                    PARTITION BY payment_id 
                    ORDER BY 
                        order_valid DESC, 
                        payment_date DESC NULLS LAST, 
                        CASE WHEN amount IS NOT NULL THEN 1 ELSE 0 END DESC,
                        amount DESC NULLS LAST,
                        ROWID
                ) as rn
            FROM dw_payments
            WHERE is_duplicate = 1
        )
        WHERE rn > 1
    );
    
    v_deleted := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Duplicate payment records deleted: ' || v_deleted);
    
    -- Reset is_duplicate flag for remaining records
    UPDATE dw_payments SET is_duplicate = 0;
    COMMIT;
END;
/

-- ============================================================================
-- STEP 4: FLAG PAYMENTS WITHOUT MATCHING ORDERS
-- ============================================================================

DECLARE
    v_orphan_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_orphan_count
    FROM dw_payments
    WHERE order_valid = 0;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Orphan payments (no matching order): ' || v_orphan_count);
END;
/

-- ============================================================================
-- STEP 5: DATA QUALITY SUMMARY
-- ============================================================================

DECLARE
    v_total NUMBER;
    v_valid_order NUMBER;
    v_invalid_order NUMBER;
    v_valid_date NUMBER;
    v_valid_amount NUMBER;
    v_valid_method NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM dw_payments;
    
    SELECT COUNT(*) INTO v_valid_order 
    FROM dw_payments WHERE order_valid = 1;
    
    SELECT COUNT(*) INTO v_invalid_order 
    FROM dw_payments WHERE order_valid = 0;
    
    SELECT COUNT(*) INTO v_valid_date 
    FROM dw_payments WHERE payment_date IS NOT NULL;
    
    SELECT COUNT(*) INTO v_valid_amount 
    FROM dw_payments WHERE amount IS NOT NULL;
    
    SELECT COUNT(*) INTO v_valid_method 
    FROM dw_payments WHERE method IS NOT NULL;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('PAYMENT DATA QUALITY SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total payments loaded: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Valid order references: ' || v_valid_order || ' (' || ROUND(v_valid_order/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Invalid/missing orders: ' || v_invalid_order || ' (' || ROUND(v_invalid_order/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid payment dates: ' || v_valid_date || ' (' || ROUND(v_valid_date/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid amounts: ' || v_valid_amount || ' (' || ROUND(v_valid_amount/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid payment methods: ' || v_valid_method || ' (' || ROUND(v_valid_method/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- Sample cleaned data
SELECT 'Sample of cleaned payment data:' as info FROM DUAL;
SELECT 
    payment_id,
    order_id,
    CASE WHEN order_valid = 1 THEN 'Valid' ELSE 'Invalid' END as order_status,
    payment_date,
    amount,
    method
FROM dw_payments
WHERE ROWNUM <= 10
ORDER BY payment_date DESC;

-- Payment method distribution
SELECT 'Payment method distribution:' as info FROM DUAL;
SELECT 
    NVL(method, 'NULL') as payment_method,
    COUNT(*) as transaction_count,
    ROUND(SUM(amount), 2) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount
FROM dw_payments
GROUP BY method
ORDER BY transaction_count DESC;

COMMIT;

SELECT 'Payment data cleansing completed!' as status FROM DUAL;
