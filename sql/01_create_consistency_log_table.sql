-- ============================================================================
-- LXN_DATA_CONSISTENCY_LOG TABLE
-- Tracks data quality issues with 0/1 flags for each validation rule
-- 0 = Pass (no issue), 1 = Fail (issue detected)
-- ============================================================================

SET SERVEROUTPUT ON;

-- Drop table if exists
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE lxn_data_consistency_log CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Existing LXN_DATA_CONSISTENCY_LOG table dropped');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No existing table to drop');
END;
/

-- Create the consistency log table
CREATE TABLE lxn_data_consistency_log (
    -- Primary Key
    log_id                      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    check_timestamp             TIMESTAMP DEFAULT SYSTIMESTAMP,
    
    -- Record Identification
    source_table                VARCHAR2(50),      -- ST_CUSTOMERS, ST_ORDERS, or ST_PAYMENTS
    record_id                   VARCHAR2(100),     -- customer_id, order_id, or payment_id
    
    -- CUSTOMER VALIDATION FLAGS (0 = Pass, 1 = Fail)
    cust_missing_id             NUMBER(1) DEFAULT 0,
    cust_missing_name           NUMBER(1) DEFAULT 0,
    cust_missing_email          NUMBER(1) DEFAULT 0,
    cust_invalid_email          NUMBER(1) DEFAULT 0,
    cust_missing_phone          NUMBER(1) DEFAULT 0,
    cust_invalid_phone          NUMBER(1) DEFAULT 0,
    cust_missing_reg_date       NUMBER(1) DEFAULT 0,
    cust_invalid_reg_date       NUMBER(1) DEFAULT 0,
    
    -- ORDER VALIDATION FLAGS (0 = Pass, 1 = Fail)
    ord_missing_id              NUMBER(1) DEFAULT 0,
    ord_missing_customer_id     NUMBER(1) DEFAULT 0,
    ord_invalid_customer        NUMBER(1) DEFAULT 0,  -- Customer doesn't exist
    ord_missing_amount          NUMBER(1) DEFAULT 0,
    ord_invalid_amount          NUMBER(1) DEFAULT 0,  -- Non-numeric amount
    ord_negative_not_refund     NUMBER(1) DEFAULT 0,  -- amount < 0 but currency not "REFUND"
    ord_missing_currency        NUMBER(1) DEFAULT 0,
    ord_invalid_currency        NUMBER(1) DEFAULT 0,  -- Unknown currency code
    ord_missing_order_date      NUMBER(1) DEFAULT 0,
    ord_invalid_order_date      NUMBER(1) DEFAULT 0,  -- Unparseable date
    ord_order_before_signup     NUMBER(1) DEFAULT 0,  -- Order date < customer signup date
    
    -- PAYMENT VALIDATION FLAGS (0 = Pass, 1 = Fail)
    pay_missing_id              NUMBER(1) DEFAULT 0,
    pay_missing_order_id        NUMBER(1) DEFAULT 0,
    pay_invalid_order           NUMBER(1) DEFAULT 0,  -- Order doesn't exist
    pay_missing_amount          NUMBER(1) DEFAULT 0,
    pay_invalid_amount          NUMBER(1) DEFAULT 0,  -- Non-numeric amount
    pay_negative_amount         NUMBER(1) DEFAULT 0,  -- Negative payment amount
    pay_amount_exceeds_order    NUMBER(1) DEFAULT 0,  -- payment.amount > order.amount
    pay_missing_payment_date    NUMBER(1) DEFAULT 0,
    pay_invalid_payment_date    NUMBER(1) DEFAULT 0,  -- Unparseable date
    pay_date_before_order       NUMBER(1) DEFAULT 0,  -- payment_date < order_date
    pay_missing_method          NUMBER(1) DEFAULT 0,
    pay_invalid_method          NUMBER(1) DEFAULT 0,  -- Unknown payment method
    pay_duplicate_payment       NUMBER(1) DEFAULT 0,  -- Duplicate order_id + amount + date
    
    -- SUMMARY
    total_issues                NUMBER(2) DEFAULT 0,  -- Count of all flags set to 1
    severity                    VARCHAR2(20),         -- LOW, MEDIUM, HIGH, CRITICAL
    
    -- Additional Context
    issue_description           VARCHAR2(4000),
    raw_data_sample             VARCHAR2(4000)
);

-- Create index for faster queries
CREATE INDEX idx_consistency_source ON lxn_data_consistency_log(source_table);
CREATE INDEX idx_consistency_timestamp ON lxn_data_consistency_log(check_timestamp);
CREATE INDEX idx_consistency_severity ON lxn_data_consistency_log(severity);

BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('TABLE CREATED SUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Table: LXN_DATA_CONSISTENCY_LOG');
    DBMS_OUTPUT.PUT_LINE('Customer validation flags: 8');
    DBMS_OUTPUT.PUT_LINE('Order validation flags: 11');
    DBMS_OUTPUT.PUT_LINE('Payment validation flags: 12');
    DBMS_OUTPUT.PUT_LINE('Total validation rules: 31');
    DBMS_OUTPUT.PUT_LINE('========================================');
END;
/

-- Verify table creation
SELECT COUNT(*) as initial_record_count 
FROM lxn_data_consistency_log;

COMMIT;
