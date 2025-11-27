-- ============================================================================
-- CLEANUP SCRIPT - Remove All Created Objects
-- Run this to revert everything back to original state
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('CLEANUP - Removing All Created Objects');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- ============================================================================
-- DROP PACKAGE
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_data_quality';
    DBMS_OUTPUT.PUT_LINE('Package PKG_DATA_QUALITY dropped');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Package not found or already dropped');
END;
/

-- ============================================================================
-- DROP VIEWS
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_consistency_summary';
    DBMS_OUTPUT.PUT_LINE('View VW_CONSISTENCY_SUMMARY dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_payment_metrics';
    DBMS_OUTPUT.PUT_LINE('View VW_CUSTOMER_PAYMENT_METRICS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_payment_delay_analysis';
    DBMS_OUTPUT.PUT_LINE('View VW_PAYMENT_DELAY_ANALYSIS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_late_payment_statistics';
    DBMS_OUTPUT.PUT_LINE('View VW_LATE_PAYMENT_STATISTICS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_quartile_segments';
    DBMS_OUTPUT.PUT_LINE('View VW_CUSTOMER_QUARTILE_SEGMENTS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_segments_comprehensive';
    DBMS_OUTPUT.PUT_LINE('View VW_CUSTOMER_SEGMENTS_COMPREHENSIVE dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_customer_risk_scores';
    DBMS_OUTPUT.PUT_LINE('View VW_CUSTOMER_RISK_SCORES dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_segment_summary_statistics';
    DBMS_OUTPUT.PUT_LINE('View VW_SEGMENT_SUMMARY_STATISTICS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_payment_method_by_segment';
    DBMS_OUTPUT.PUT_LINE('View VW_PAYMENT_METHOD_BY_SEGMENT dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_monthly_payment_trends';
    DBMS_OUTPUT.PUT_LINE('View VW_MONTHLY_PAYMENT_TRENDS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- DROP DW TABLES (in correct order due to foreign keys)
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_payments CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table DW_PAYMENTS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_orders CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table DW_ORDERS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dw_customers CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table DW_CUSTOMERS dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- DROP CONSISTENCY LOG TABLE
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE lxn_data_consistency_log CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table LXN_DATA_CONSISTENCY_LOG dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- DROP MAPPING TABLES
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE currency_mapping CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table CURRENCY_MAPPING dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE payment_method_mapping CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table PAYMENT_METHOD_MAPPING dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- DROP FUNCTIONS
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION extract_numeric_id';
    DBMS_OUTPUT.PUT_LINE('Function EXTRACT_NUMERIC_ID dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION is_valid_email';
    DBMS_OUTPUT.PUT_LINE('Function IS_VALID_EMAIL dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION clean_phone';
    DBMS_OUTPUT.PUT_LINE('Function CLEAN_PHONE dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION parse_date_multi';
    DBMS_OUTPUT.PUT_LINE('Function PARSE_DATE_MULTI dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION clean_amount';
    DBMS_OUTPUT.PUT_LINE('Function CLEAN_AMOUNT dropped');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('CLEANUP COMPLETED SUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('All created objects have been removed.');
    DBMS_OUTPUT.PUT_LINE('Your database is back to the original state.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Only ST_CUSTOMERS, ST_ORDERS, ST_PAYMENTS remain.');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
END;
/

-- Verify cleanup
SELECT 'Remaining user objects:' as info FROM DUAL;
SELECT object_name, object_type 
FROM user_objects 
WHERE object_name LIKE '%CUSTOMER%' 
   OR object_name LIKE '%ORDER%'
   OR object_name LIKE '%PAYMENT%'
   OR object_name LIKE '%CONSISTENCY%'
   OR object_name LIKE 'PKG_%'
ORDER BY object_type, object_name;
