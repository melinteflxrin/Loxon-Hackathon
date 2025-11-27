-- ============================================================================
-- QUERY LXN_DATA_CONSISTENCY_LOG - Useful Analytics
-- Run these queries after populating the consistency log
-- ============================================================================

-- ============================================================================
-- 1. EXECUTIVE SUMMARY
-- ============================================================================
SELECT 
    COUNT(DISTINCT record_id) as total_records_with_issues,
    COUNT(*) as total_issue_records,
    SUM(total_issues) as total_validation_failures,
    ROUND(AVG(total_issues), 2) as avg_issues_per_record,
    COUNT(CASE WHEN severity = 'CRITICAL' THEN 1 END) as critical_records,
    COUNT(CASE WHEN severity = 'HIGH' THEN 1 END) as high_records,
    COUNT(CASE WHEN severity = 'MEDIUM' THEN 1 END) as medium_records
FROM lxn_data_consistency_log;

-- ============================================================================
-- 2. ISSUES BY SOURCE TABLE
-- ============================================================================
SELECT 
    source_table,
    COUNT(*) as records_with_issues,
    SUM(total_issues) as total_issues,
    ROUND(AVG(total_issues), 2) as avg_issues_per_record,
    MAX(total_issues) as max_issues_in_one_record
FROM lxn_data_consistency_log
GROUP BY source_table
ORDER BY total_issues DESC;

-- ============================================================================
-- 3. TOP 10 MOST COMMON VALIDATION FAILURES
-- ============================================================================
WITH issue_counts AS (
    SELECT 'cust_missing_id' as rule_name, 'Customer' as category, SUM(cust_missing_id) as count FROM lxn_data_consistency_log UNION ALL
    SELECT 'cust_missing_email', 'Customer', SUM(cust_missing_email) FROM lxn_data_consistency_log UNION ALL
    SELECT 'cust_invalid_email', 'Customer', SUM(cust_invalid_email) FROM lxn_data_consistency_log UNION ALL
    SELECT 'cust_missing_phone', 'Customer', SUM(cust_missing_phone) FROM lxn_data_consistency_log UNION ALL
    SELECT 'ord_missing_customer_id', 'Order', SUM(ord_missing_customer_id) FROM lxn_data_consistency_log UNION ALL
    SELECT 'ord_invalid_customer', 'Order', SUM(ord_invalid_customer) FROM lxn_data_consistency_log UNION ALL
    SELECT 'ord_negative_not_refund', 'Order', SUM(ord_negative_not_refund) FROM lxn_data_consistency_log UNION ALL
    SELECT 'ord_missing_amount', 'Order', SUM(ord_missing_amount) FROM lxn_data_consistency_log UNION ALL
    SELECT 'pay_invalid_order', 'Payment', SUM(pay_invalid_order) FROM lxn_data_consistency_log UNION ALL
    SELECT 'pay_amount_exceeds_order', 'Payment', SUM(pay_amount_exceeds_order) FROM lxn_data_consistency_log UNION ALL
    SELECT 'pay_date_before_order', 'Payment', SUM(pay_date_before_order) FROM lxn_data_consistency_log UNION ALL
    SELECT 'pay_negative_amount', 'Payment', SUM(pay_negative_amount) FROM lxn_data_consistency_log
)
SELECT 
    rule_name,
    category,
    count as occurrences
FROM issue_counts
WHERE count > 0
ORDER BY count DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- 4. SEVERITY DISTRIBUTION
-- ============================================================================
SELECT 
    severity,
    source_table,
    COUNT(*) as record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY source_table), 2) as pct_of_table
FROM lxn_data_consistency_log
GROUP BY severity, source_table
ORDER BY 
    source_table,
    CASE severity 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END;

-- ============================================================================
-- 6. SAMPLE OF CRITICAL ISSUES (for investigation)
-- ============================================================================
SELECT 
    log_id,
    source_table,
    record_id,
    total_issues,
    severity,
    issue_description,
    SUBSTR(raw_data_sample, 1, 100) as sample_data,
    check_timestamp
FROM lxn_data_consistency_log
WHERE severity = 'CRITICAL'
ORDER BY total_issues DESC, check_timestamp DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 7. CUSTOMER-SPECIFIC VALIDATION FAILURES
-- ============================================================================
SELECT 
    record_id as customer_id,
    cust_missing_id,
    cust_missing_email,
    cust_invalid_email,
    cust_missing_phone,
    cust_invalid_phone,
    total_issues,
    severity
FROM lxn_data_consistency_log
WHERE source_table = 'ST_CUSTOMERS'
ORDER BY total_issues DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 8. ORDER-SPECIFIC VALIDATION FAILURES
-- ============================================================================
SELECT 
    record_id as order_id,
    ord_invalid_customer,
    ord_negative_not_refund,
    ord_missing_amount,
    ord_invalid_currency,
    total_issues,
    severity
FROM lxn_data_consistency_log
WHERE source_table = 'ST_ORDERS'
ORDER BY total_issues DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 9. PAYMENT-SPECIFIC VALIDATION FAILURES
-- ============================================================================
SELECT 
    record_id as payment_id,
    pay_invalid_order,
    pay_amount_exceeds_order,
    pay_date_before_order,
    pay_negative_amount,
    pay_invalid_method,
    total_issues,
    severity
FROM lxn_data_consistency_log
WHERE source_table = 'ST_PAYMENTS'
ORDER BY total_issues DESC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- 10. DATA QUALITY SCORE (by table)
-- ============================================================================
WITH table_totals AS (
    SELECT 'ST_CUSTOMERS' as table_name, COUNT(*) as total_records FROM st_customers UNION ALL
    SELECT 'ST_ORDERS', COUNT(*) FROM st_orders UNION ALL
    SELECT 'ST_PAYMENTS', COUNT(*) FROM st_payments
),
issue_counts AS (
    SELECT 
        source_table,
        COUNT(DISTINCT record_id) as records_with_issues
    FROM lxn_data_consistency_log
    GROUP BY source_table
)
SELECT 
    t.table_name,
    t.total_records,
    NVL(i.records_with_issues, 0) as records_with_issues,
    t.total_records - NVL(i.records_with_issues, 0) as clean_records,
    ROUND((t.total_records - NVL(i.records_with_issues, 0)) * 100.0 / t.total_records, 2) as quality_score_pct
FROM table_totals t
LEFT JOIN issue_counts i ON t.table_name = i.source_table
ORDER BY quality_score_pct DESC;

