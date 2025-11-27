-- ============================================================================
-- DATA CONSISTENCY LOG TABLE
-- Tracks data quality issues with 0/1 flags for each validation rule
-- Run BEFORE cleansing scripts to log issues from raw data
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE CONSISTENCY LOG TABLE
-- ============================================================================

-- Drop table if exists
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE lxn_data_consistency_log CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE lxn_data_consistency_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    check_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    table_name VARCHAR2(50) NOT NULL,
    record_id VARCHAR2(100) NOT NULL,
    
    -- Customer validation flags (0 = pass, 1 = fail)
    cust_missing_id NUMBER(1) DEFAULT 0,
    cust_missing_name NUMBER(1) DEFAULT 0,
    cust_missing_email NUMBER(1) DEFAULT 0,
    cust_invalid_email NUMBER(1) DEFAULT 0,
    cust_missing_phone NUMBER(1) DEFAULT 0,
    cust_invalid_phone NUMBER(1) DEFAULT 0,
    cust_missing_reg_date NUMBER(1) DEFAULT 0,
    cust_invalid_reg_date NUMBER(1) DEFAULT 0,
    
    -- Order validation flags (0 = pass, 1 = fail)
    ord_missing_customer NUMBER(1) DEFAULT 0,
    ord_invalid_customer NUMBER(1) DEFAULT 0,
    ord_missing_date NUMBER(1) DEFAULT 0,
    ord_invalid_date NUMBER(1) DEFAULT 0,
    ord_missing_amount NUMBER(1) DEFAULT 0,
    ord_invalid_amount NUMBER(1) DEFAULT 0,
    ord_negative_not_refund NUMBER(1) DEFAULT 0,
    ord_missing_currency NUMBER(1) DEFAULT 0,
    ord_invalid_currency NUMBER(1) DEFAULT 0,
    
    -- Payment validation flags (0 = pass, 1 = fail)
    pay_missing_order NUMBER(1) DEFAULT 0,
    pay_invalid_order NUMBER(1) DEFAULT 0,
    pay_missing_date NUMBER(1) DEFAULT 0,
    pay_invalid_date NUMBER(1) DEFAULT 0,
    pay_missing_amount NUMBER(1) DEFAULT 0,
    pay_invalid_amount NUMBER(1) DEFAULT 0,
    pay_date_before_order NUMBER(1) DEFAULT 0,
    pay_amount_exceeds_order NUMBER(1) DEFAULT 0,
    pay_missing_method NUMBER(1) DEFAULT 0,
    pay_invalid_method NUMBER(1) DEFAULT 0,
    pay_duplicate_id NUMBER(1) DEFAULT 0,
    
    -- Additional context
    issue_description VARCHAR2(500),
    raw_value VARCHAR2(500),
    
    CONSTRAINT chk_table_name CHECK (table_name IN ('ST_CUSTOMERS', 'ST_ORDERS', 'ST_PAYMENTS'))
);

-- Create indexes for performance
CREATE INDEX idx_consistency_table ON lxn_data_consistency_log(table_name);
CREATE INDEX idx_consistency_timestamp ON lxn_data_consistency_log(check_timestamp);
CREATE INDEX idx_consistency_record ON lxn_data_consistency_log(record_id);

COMMENT ON TABLE lxn_data_consistency_log IS 'Data quality validation log with 0/1 flags for each rule';

-- ============================================================================
-- STEP 2: CREATE SUMMARY VIEW
-- ============================================================================

CREATE OR REPLACE VIEW vw_consistency_summary AS
SELECT 
    table_name,
    COUNT(*) as total_issues,
    -- Customer issues
    SUM(cust_missing_id) as cust_missing_id_count,
    SUM(cust_missing_name) as cust_missing_name_count,
    SUM(cust_missing_email) as cust_missing_email_count,
    SUM(cust_invalid_email) as cust_invalid_email_count,
    SUM(cust_missing_phone) as cust_missing_phone_count,
    SUM(cust_invalid_phone) as cust_invalid_phone_count,
    SUM(cust_missing_reg_date) as cust_missing_reg_date_count,
    SUM(cust_invalid_reg_date) as cust_invalid_reg_date_count,
    -- Order issues
    SUM(ord_missing_customer) as ord_missing_customer_count,
    SUM(ord_invalid_customer) as ord_invalid_customer_count,
    SUM(ord_missing_date) as ord_missing_date_count,
    SUM(ord_invalid_date) as ord_invalid_date_count,
    SUM(ord_missing_amount) as ord_missing_amount_count,
    SUM(ord_invalid_amount) as ord_invalid_amount_count,
    SUM(ord_negative_not_refund) as ord_negative_not_refund_count,
    SUM(ord_missing_currency) as ord_missing_currency_count,
    SUM(ord_invalid_currency) as ord_invalid_currency_count,
    -- Payment issues
    SUM(pay_missing_order) as pay_missing_order_count,
    SUM(pay_invalid_order) as pay_invalid_order_count,
    SUM(pay_missing_date) as pay_missing_date_count,
    SUM(pay_invalid_date) as pay_invalid_date_count,
    SUM(pay_missing_amount) as pay_missing_amount_count,
    SUM(pay_invalid_amount) as pay_invalid_amount_count,
    SUM(pay_date_before_order) as pay_date_before_order_count,
    SUM(pay_amount_exceeds_order) as pay_amount_exceeds_order_count,
    SUM(pay_missing_method) as pay_missing_method_count,
    SUM(pay_invalid_method) as pay_invalid_method_count,
    SUM(pay_duplicate_id) as pay_duplicate_id_count
FROM lxn_data_consistency_log
GROUP BY table_name;

COMMENT ON TABLE vw_consistency_summary IS 'Summary of data quality issues by table';

SELECT 'Consistency log table created successfully!' as status FROM DUAL;
