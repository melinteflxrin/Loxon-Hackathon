-- ============================================================================
-- ORDER DATA CLEANSING SCRIPT
-- Cleans ST_ORDERS into DW_ORDERS
-- Run after: 02_cleanse_customers.sql
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('ORDER DATA CLEANSING STARTED');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- ============================================================================
-- STEP 1: INSERT AND CLEAN ORDER DATA
-- ============================================================================

INSERT INTO dw_orders (
    order_id,
    customer_id,
    customer_id_raw,
    customer_valid,
    order_date,
    order_date_raw,
    amount,
    amount_raw,
    currency,
    currency_raw,
    is_refund
)
SELECT 
    o.order_id,
    
    -- Link to cleaned customer_id
    c.customer_id,
    o.customer_id as customer_id_raw,
    
    -- Mark if customer reference is valid
    CASE 
        WHEN c.customer_id IS NOT NULL THEN 1
        WHEN o.customer_id IS NULL OR UPPER(o.customer_id) = 'NULL' OR o.customer_id = '' THEN 0
        ELSE 0
    END as customer_valid,
    
    -- Parse order date
    parse_date_multi(o.order_date) as order_date,
    o.order_date as order_date_raw,
    
    -- Clean amount (take absolute value, handle negative as refunds)
    ABS(clean_amount(o.amount)) as amount,
    o.amount as amount_raw,
    
    -- Normalize currency using mapping table
    COALESCE(
        cm.clean_currency,
        CASE 
            WHEN UPPER(o.currency) LIKE '%USD%' OR UPPER(o.currency) = 'US$' THEN 'USD'
            WHEN UPPER(o.currency) LIKE '%EUR%' THEN 'EUR'
            WHEN UPPER(o.currency) = 'HUF' THEN 'HUF'
            ELSE NULL
        END
    ) as currency,
    o.currency as currency_raw,
    
    -- Mark refunds (negative amounts)
    CASE 
        WHEN clean_amount(o.amount) < 0 THEN 1
        ELSE 0
    END as is_refund
    
FROM st_orders o
LEFT JOIN currency_mapping cm ON UPPER(TRIM(o.currency)) = cm.raw_currency
LEFT JOIN dw_customers c ON o.customer_id = c.customer_id_raw
WHERE o.order_id IS NOT NULL;

COMMIT;

-- ============================================================================
-- STEP 2: HANDLE DUPLICATE ORDER_IDs
-- ============================================================================

DECLARE
    v_dup_count NUMBER;
    v_deleted NUMBER := 0;
BEGIN
    -- Find duplicate order_ids
    SELECT COUNT(*) INTO v_dup_count
    FROM (
        SELECT order_id, COUNT(*) as cnt
        FROM dw_orders
        GROUP BY order_id
        HAVING COUNT(*) > 1
    );
    
    DBMS_OUTPUT.PUT_LINE('Duplicate order IDs found: ' || v_dup_count);
    
    -- For duplicates, keep the one with valid customer and most recent date
    -- Delete others
    IF v_dup_count > 0 THEN
        DELETE FROM dw_orders
        WHERE ROWID IN (
            SELECT rid FROM (
                SELECT 
                    ROWID as rid,
                    ROW_NUMBER() OVER (
                        PARTITION BY order_id 
                        ORDER BY customer_valid DESC, order_date DESC NULLS LAST, amount DESC NULLS LAST, ROWID
                    ) as rn
                FROM dw_orders
            )
            WHERE rn > 1
        );
        
        v_deleted := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Duplicate orders deleted: ' || v_deleted);
    END IF;
END;
/

-- ============================================================================
-- STEP 3: UPDATE CURRENCY FROM AMOUNT STRING
-- ============================================================================

-- Some orders have currency embedded in amount field (e.g., "1047.39 USD")
UPDATE dw_orders
SET currency = CASE
    WHEN UPPER(amount_raw) LIKE '%USD%' THEN 'USD'
    WHEN UPPER(amount_raw) LIKE '%EUR%' THEN 'EUR'
    WHEN UPPER(amount_raw) LIKE '%HUF%' THEN 'HUF'
    ELSE currency
END
WHERE currency IS NULL 
  AND amount_raw IS NOT NULL;

COMMIT;

-- ============================================================================
-- STEP 4: DATA QUALITY SUMMARY
-- ============================================================================

DECLARE
    v_total NUMBER;
    v_valid_customer NUMBER;
    v_invalid_customer NUMBER;
    v_valid_date NUMBER;
    v_valid_amount NUMBER;
    v_refunds NUMBER;
    v_null_currency NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM dw_orders;
    
    SELECT COUNT(*) INTO v_valid_customer 
    FROM dw_orders WHERE customer_valid = 1;
    
    SELECT COUNT(*) INTO v_invalid_customer 
    FROM dw_orders WHERE customer_valid = 0;
    
    SELECT COUNT(*) INTO v_valid_date 
    FROM dw_orders WHERE order_date IS NOT NULL;
    
    SELECT COUNT(*) INTO v_valid_amount 
    FROM dw_orders WHERE amount IS NOT NULL;
    
    SELECT COUNT(*) INTO v_refunds 
    FROM dw_orders WHERE is_refund = 1;
    
    SELECT COUNT(*) INTO v_null_currency 
    FROM dw_orders WHERE currency IS NULL;
    
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('ORDER DATA QUALITY SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total orders loaded: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Valid customer references: ' || v_valid_customer || ' (' || ROUND(v_valid_customer/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Invalid/missing customers: ' || v_invalid_customer || ' (' || ROUND(v_invalid_customer/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid order dates: ' || v_valid_date || ' (' || ROUND(v_valid_date/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Valid amounts: ' || v_valid_amount || ' (' || ROUND(v_valid_amount/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Refund orders (negative): ' || v_refunds || ' (' || ROUND(v_refunds/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('Missing currency: ' || v_null_currency || ' (' || ROUND(v_null_currency/v_total*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- Sample cleaned data
SELECT 'Sample of cleaned order data:' as info FROM DUAL;
SELECT 
    order_id,
    customer_id,
    customer_id_raw,
    CASE WHEN customer_valid = 1 THEN 'Valid' ELSE 'Invalid' END as cust_status,
    order_date,
    amount,
    currency,
    CASE WHEN is_refund = 1 THEN 'Refund' ELSE 'Normal' END as order_type
FROM dw_orders
WHERE ROWNUM <= 10
ORDER BY order_date DESC;

-- Currency distribution
SELECT 'Currency distribution:' as info FROM DUAL;
SELECT 
    NVL(currency, 'NULL') as currency,
    COUNT(*) as order_count,
    ROUND(SUM(amount), 2) as total_amount
FROM dw_orders
GROUP BY currency
ORDER BY order_count DESC;

COMMIT;
