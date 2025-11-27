-- ============================================================================
-- DATA QUALITY REPORT
-- Comprehensive report on cleaned data warehouse tables
-- Run after all cleansing scripts
-- ============================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 100;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('                    DATA QUALITY REPORT');
    DBMS_OUTPUT.PUT_LINE('                    ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
END;
/

-- ============================================================================
-- SECTION 1: OVERALL SUMMARY
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 1. OVERALL DATA SUMMARY
PROMPT ========================================

SELECT 
    'Customers' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT customer_id) as unique_keys
FROM dw_customers
UNION ALL
SELECT 
    'Orders' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT order_id) as unique_keys
FROM dw_orders
UNION ALL
SELECT 
    'Payments' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT payment_id) as unique_keys
FROM dw_payments;

-- ============================================================================
-- SECTION 2: CUSTOMER DATA QUALITY
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 2. CUSTOMER DATA QUALITY
PROMPT ========================================

SELECT 
    'Total Customers' as metric,
    TO_CHAR(COUNT(*)) as count,
    '100.0%' as percentage
FROM dw_customers
UNION ALL
SELECT 
    '  Valid Emails' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_customers), 1)) || '%' as percentage
FROM dw_customers 
WHERE email_valid = 1
UNION ALL
SELECT 
    '  Invalid Emails' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_customers), 1)) || '%' as percentage
FROM dw_customers 
WHERE email_valid = 0 OR email IS NULL
UNION ALL
SELECT 
    '  Valid Phone Numbers' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_customers), 1)) || '%' as percentage
FROM dw_customers 
WHERE phone_cleaned IS NOT NULL
UNION ALL
SELECT 
    '  Valid Registration Dates' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_customers), 1)) || '%' as percentage
FROM dw_customers 
WHERE reg_date IS NOT NULL;

-- ============================================================================
-- SECTION 3: ORDER DATA QUALITY
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 3. ORDER DATA QUALITY
PROMPT ========================================

SELECT 
    'Total Orders' as metric,
    TO_CHAR(COUNT(*)) as count,
    '100.0%' as percentage
FROM dw_orders
UNION ALL
SELECT 
    '  Valid Customer References' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE customer_valid = 1
UNION ALL
SELECT 
    '  Invalid/Missing Customer' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE customer_valid = 0
UNION ALL
SELECT 
    '  Valid Order Dates' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE order_date IS NOT NULL
UNION ALL
SELECT 
    '  Valid Amounts' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE amount IS NOT NULL
UNION ALL
SELECT 
    '  Refund Orders (Negative)' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE is_refund = 1
UNION ALL
SELECT 
    '  Missing Currency' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_orders), 1)) || '%' as percentage
FROM dw_orders 
WHERE currency IS NULL;

-- ============================================================================
-- SECTION 4: PAYMENT DATA QUALITY
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 4. PAYMENT DATA QUALITY
PROMPT ========================================

SELECT 
    'Total Payments' as metric,
    TO_CHAR(COUNT(*)) as count,
    '100.0%' as percentage
FROM dw_payments
UNION ALL
SELECT 
    '  Valid Order References' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_payments), 1)) || '%' as percentage
FROM dw_payments 
WHERE order_valid = 1
UNION ALL
SELECT 
    '  Orphan Payments (No Order)' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_payments), 1)) || '%' as percentage
FROM dw_payments 
WHERE order_valid = 0
UNION ALL
SELECT 
    '  Valid Payment Dates' as metric,
    TO_CHAR(COUNT(*) ) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_payments), 1)) || '%' as percentage
FROM dw_payments 
WHERE payment_date IS NOT NULL
UNION ALL
SELECT 
    '  Valid Amounts' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_payments), 1)) || '%' as percentage
FROM dw_payments 
WHERE amount IS NOT NULL
UNION ALL
SELECT 
    '  Valid Payment Methods' as metric,
    TO_CHAR(COUNT(*)) as count,
    TO_CHAR(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dw_payments), 1)) || '%' as percentage
FROM dw_payments 
WHERE method IS NOT NULL;

-- ============================================================================
-- SECTION 5: BUSINESS METRICS
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 5. BUSINESS METRICS
PROMPT ========================================

-- Currency distribution
PROMPT
PROMPT Currency Distribution:
SELECT 
    NVL(currency, 'UNKNOWN') as currency,
    COUNT(*) as order_count,
    TO_CHAR(ROUND(SUM(amount), 2), '999,999,999.99') as total_amount
FROM dw_orders
GROUP BY currency
ORDER BY COUNT(*) DESC;

-- Payment method distribution
PROMPT
PROMPT Payment Method Distribution:
SELECT 
    NVL(method, 'UNKNOWN') as payment_method,
    COUNT(*) as transaction_count,
    TO_CHAR(ROUND(SUM(amount), 2), '999,999,999.99') as total_amount,
    TO_CHAR(ROUND(AVG(amount), 2), '999,999.99') as avg_amount
FROM dw_payments
GROUP BY method
ORDER BY COUNT(*) DESC;

-- Date range
PROMPT
PROMPT Date Ranges:
SELECT 
    'Customer Registrations' as metric,
    TO_CHAR(MIN(reg_date), 'YYYY-MM-DD') as earliest_date,
    TO_CHAR(MAX(reg_date), 'YYYY-MM-DD') as latest_date,
    TO_CHAR(MAX(reg_date) - MIN(reg_date)) || ' days' as date_span
FROM dw_customers
WHERE reg_date IS NOT NULL
UNION ALL
SELECT 
    'Orders' as metric,
    TO_CHAR(MIN(order_date), 'YYYY-MM-DD') as earliest_date,
    TO_CHAR(MAX(order_date), 'YYYY-MM-DD') as latest_date,
    TO_CHAR(MAX(order_date) - MIN(order_date)) || ' days' as date_span
FROM dw_orders
WHERE order_date IS NOT NULL
UNION ALL
SELECT 
    'Payments' as metric,
    TO_CHAR(MIN(payment_date), 'YYYY-MM-DD') as earliest_date,
    TO_CHAR(MAX(payment_date), 'YYYY-MM-DD') as latest_date,
    TO_CHAR(MAX(payment_date) - MIN(payment_date)) || ' days' as date_span
FROM dw_payments
WHERE payment_date IS NOT NULL;

-- ============================================================================
-- SECTION 6: DATA INTEGRITY CHECKS
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 6. DATA INTEGRITY CHECKS
PROMPT ========================================

-- Orders without customers
PROMPT
PROMPT Orders Without Valid Customers (Top 10):
SELECT order_id, customer_id_raw, order_date, amount, currency
FROM dw_orders
WHERE customer_valid = 0
  AND ROWNUM <= 10
ORDER BY order_date DESC;

-- Payments without orders
PROMPT
PROMPT Payments Without Valid Orders (Top 10):
SELECT payment_id, order_id, payment_date, amount, method
FROM dw_payments
WHERE order_valid = 0
  AND ROWNUM <= 10
ORDER BY payment_date DESC;

-- Refund orders
PROMPT
PROMPT Refund Orders (Negative Amounts - Top 10):
SELECT order_id, customer_id, order_date, amount, currency
FROM dw_orders
WHERE is_refund = 1
  AND ROWNUM <= 10
ORDER BY amount DESC;

-- ============================================================================
-- SECTION 7: TOP CUSTOMERS BY REVENUE
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT 7. TOP 10 CUSTOMERS BY REVENUE
PROMPT ========================================

SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    TO_CHAR(ROUND(SUM(o.amount), 2), '999,999,999.99') as total_revenue
FROM dw_customers c
JOIN dw_orders o ON c.customer_id = o.customer_id
WHERE o.amount IS NOT NULL
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY SUM(o.amount) DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

PROMPT
PROMPT ========================================
PROMPT DATA QUALITY REPORT COMPLETED
PROMPT ========================================
PROMPT
PROMPT Next Steps:
PROMPT 1. Review data quality metrics above
PROMPT 2. Run create_views.sql to create analytical views
PROMPT 3. Export cleaned data: SELECT * FROM dw_customers|dw_orders|dw_payments
PROMPT 4. Use for Python AI analysis
PROMPT ========================================
