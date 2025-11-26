-- ============================================================================
-- CREATE VIEWS FOR CUSTOMER PAYMENT BEHAVIOR SEGMENTATION
-- These views will be visible in SQL Developer schema browser
-- Execute these after loading customers_clean, orders_clean, payments_clean
-- ============================================================================

-- ============================================================================
-- VIEW 1: CUSTOMER PAYMENT METRICS (Base metrics for all customers)
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_payment_metrics AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.reg_date,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(p.payment_id) as total_payments,
    SUM(p.amount) as total_revenue,
    AVG(p.amount) as avg_payment_amount,
    MIN(p.payment_date) as first_payment_date,
    MAX(p.payment_date) as last_payment_date,
    SYSDATE - MAX(p.payment_date) as days_since_last_payment,
    AVG(p.payment_date - o.order_date) as avg_payment_delay,
    MAX(p.payment_date - o.order_date) as max_payment_delay,
    MIN(p.payment_date - o.order_date) as min_payment_delay,
    STDDEV(p.payment_date - o.order_date) as stddev_payment_delay
FROM customers_clean c
LEFT JOIN orders_clean o ON c.customer_id = o.customer_id
LEFT JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name, c.email, c.reg_date;

COMMENT ON TABLE vw_customer_payment_metrics IS 'Base payment metrics per customer including delays, amounts, and activity';

-- ============================================================================
-- VIEW 2: PAYMENT DELAY ANALYSIS (Required KPI - Average Payment Delay)
-- ============================================================================
CREATE OR REPLACE VIEW vw_payment_delay_analysis AS
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(p.payment_id) as total_payments,
    ROUND(AVG(p.payment_date - o.order_date), 2) as avg_payment_delay_days,
    MIN(p.payment_date - o.order_date) as min_delay_days,
    MAX(p.payment_date - o.order_date) as max_delay_days,
    ROUND(STDDEV(p.payment_date - o.order_date), 2) as stddev_delay_days,
    CASE 
        WHEN AVG(p.payment_date - o.order_date) < -30 THEN 'Consistently Early'
        WHEN AVG(p.payment_date - o.order_date) < 0 THEN 'Early Payer'
        WHEN AVG(p.payment_date - o.order_date) <= 30 THEN 'On-Time Payer'
        WHEN AVG(p.payment_date - o.order_date) <= 90 THEN 'Late Payer'
        ELSE 'Very Late Payer'
    END as payment_behavior
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(p.payment_id) > 0;

COMMENT ON TABLE vw_payment_delay_analysis IS 'Average payment delay per customer - Required KPI';

-- ============================================================================
-- VIEW 3: LATE PAYMENT STATISTICS (Required KPI - Late vs Total Payments)
-- ============================================================================
CREATE OR REPLACE VIEW vw_late_payment_statistics AS
SELECT 
    c.customer_id,
    c.full_name,
    COUNT(p.payment_id) as total_payments,
    SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) as late_payments_count,
    SUM(CASE WHEN p.payment_date - o.order_date <= 30 AND p.payment_date - o.order_date >= 0 THEN 1 ELSE 0 END) as on_time_payments_count,
    SUM(CASE WHEN p.payment_date - o.order_date < 0 THEN 1 ELSE 0 END) as early_payments_count,
    ROUND(SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(p.payment_id), 2) as late_payment_percentage
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name
HAVING COUNT(p.payment_id) > 0;

COMMENT ON TABLE vw_late_payment_statistics IS 'Late payment counts and percentages - Required KPI';

-- ============================================================================
-- VIEW 4: QUARTILE SEGMENTATION (Required KPI - NTILE)
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_quartile_segments AS
WITH customer_delays AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        AVG(p.payment_date - o.order_date) as avg_payment_delay,
        COUNT(p.payment_id) as total_payments,
        SUM(p.amount) as total_revenue
    FROM customers_clean c
    JOIN orders_clean o ON c.customer_id = o.customer_id
    JOIN payments_clean p ON o.order_id = p.order_id
    GROUP BY c.customer_id, c.full_name, c.email
)
SELECT 
    customer_id,
    full_name,
    email,
    ROUND(avg_payment_delay, 2) as avg_payment_delay,
    total_payments,
    ROUND(total_revenue, 2) as total_revenue,
    NTILE(4) OVER (ORDER BY avg_payment_delay) as delay_quartile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 1 THEN 'Q1 - Best Payers (Earliest)'
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 2 THEN 'Q2 - Good Payers'
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 3 THEN 'Q3 - Moderate Payers'
        ELSE 'Q4 - Worst Payers (Latest)'
    END as quartile_description
FROM customer_delays;

COMMENT ON TABLE vw_customer_quartile_segments IS 'Customer segmentation using NTILE(4) quartiles - Required KPI';

-- ============================================================================
-- VIEW 5: COMPREHENSIVE CUSTOMER SEGMENTS (Main Deliverable)
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_segments_comprehensive AS
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.email,
        c.reg_date,
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(p.payment_id) as total_payments,
        SUM(p.amount) as total_revenue,
        AVG(p.amount) as avg_payment_amount,
        AVG(p.payment_date - o.order_date) as avg_payment_delay,
        MAX(p.payment_date - o.order_date) as max_payment_delay,
        MIN(p.payment_date - o.order_date) as min_payment_delay,
        SYSDATE - MAX(p.payment_date) as days_since_last_payment,
        SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) as late_payments,
        SUM(CASE WHEN p.payment_date - o.order_date <= 30 AND p.payment_date - o.order_date >= 0 THEN 1 ELSE 0 END) as on_time_payments,
        SUM(CASE WHEN p.payment_date - o.order_date < 0 THEN 1 ELSE 0 END) as early_payments
    FROM customers_clean c
    LEFT JOIN orders_clean o ON c.customer_id = o.customer_id
    LEFT JOIN payments_clean p ON o.order_id = p.order_id
    GROUP BY c.customer_id, c.full_name, c.email, c.reg_date
)
SELECT 
    customer_id,
    full_name,
    email,
    total_orders,
    total_payments,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_payment_amount, 2) as avg_payment_amount,
    ROUND(avg_payment_delay, 2) as avg_payment_delay_days,
    max_payment_delay as worst_delay_days,
    days_since_last_payment as recency_days,
    late_payments,
    on_time_payments,
    early_payments,
    ROUND(late_payments * 100.0 / NULLIF(total_payments, 0), 2) as late_payment_pct,
    -- Quartile segmentation
    NTILE(4) OVER (ORDER BY avg_payment_delay) as payment_delay_quartile,
    -- Revenue quartile
    NTILE(4) OVER (ORDER BY total_revenue) as revenue_quartile,
    -- Payment behavior category
    CASE 
        WHEN avg_payment_delay < -30 THEN 'Very Early Payer'
        WHEN avg_payment_delay < 0 THEN 'Early Payer'
        WHEN avg_payment_delay <= 30 THEN 'On-Time Payer'
        WHEN avg_payment_delay <= 90 THEN 'Late Payer'
        ELSE 'Very Late Payer'
    END as payment_category,
    -- Customer value segment
    CASE 
        WHEN total_revenue > 8000 AND avg_payment_delay < 30 THEN 'VIP Customer'
        WHEN avg_payment_delay > 180 OR (late_payments * 100.0 / NULLIF(total_payments, 0)) > 80 THEN 'High Risk Customer'
        WHEN days_since_last_payment > 365 THEN 'Inactive Customer'
        ELSE 'Standard Customer'
    END as customer_segment
FROM customer_metrics
WHERE total_payments > 0;

COMMENT ON TABLE vw_customer_segments_comprehensive IS 'Comprehensive customer segmentation combining all metrics - Main deliverable';

-- ============================================================================
-- VIEW 6: CUSTOMER RISK SCORING
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_risk_scores AS
SELECT 
    c.customer_id,
    c.full_name,
    ROUND(AVG(p.payment_date - o.order_date), 2) as avg_delay,
    MAX(p.payment_date - o.order_date) as max_delay,
    SYSDATE - MAX(p.payment_date) as recency_days,
    COUNT(p.payment_id) as total_payments,
    ROUND(SUM(p.amount), 2) as total_revenue,
    -- Risk score calculation (0-100, higher = more risky)
    ROUND(
        CASE 
            WHEN AVG(p.payment_date - o.order_date) > 180 THEN 40
            WHEN AVG(p.payment_date - o.order_date) > 90 THEN 30
            WHEN AVG(p.payment_date - o.order_date) > 30 THEN 15
            ELSE 5
        END +
        CASE 
            WHEN MAX(p.payment_date - o.order_date) > 300 THEN 30
            WHEN MAX(p.payment_date - o.order_date) > 180 THEN 20
            WHEN MAX(p.payment_date - o.order_date) > 90 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN SYSDATE - MAX(p.payment_date) > 365 THEN 30
            WHEN SYSDATE - MAX(p.payment_date) > 180 THEN 20
            WHEN SYSDATE - MAX(p.payment_date) > 90 THEN 10
            ELSE 0
        END
    , 0) as risk_score,
    CASE 
        WHEN ROUND(
            CASE WHEN AVG(p.payment_date - o.order_date) > 180 THEN 40
                 WHEN AVG(p.payment_date - o.order_date) > 90 THEN 30
                 WHEN AVG(p.payment_date - o.order_date) > 30 THEN 15
                 ELSE 5 END +
            CASE WHEN MAX(p.payment_date - o.order_date) > 300 THEN 30
                 WHEN MAX(p.payment_date - o.order_date) > 180 THEN 20
                 WHEN MAX(p.payment_date - o.order_date) > 90 THEN 10
                 ELSE 0 END +
            CASE WHEN SYSDATE - MAX(p.payment_date) > 365 THEN 30
                 WHEN SYSDATE - MAX(p.payment_date) > 180 THEN 20
                 WHEN SYSDATE - MAX(p.payment_date) > 90 THEN 10
                 ELSE 0 END, 0) >= 70 THEN 'High Risk'
        WHEN ROUND(
            CASE WHEN AVG(p.payment_date - o.order_date) > 180 THEN 40
                 WHEN AVG(p.payment_date - o.order_date) > 90 THEN 30
                 WHEN AVG(p.payment_date - o.order_date) > 30 THEN 15
                 ELSE 5 END +
            CASE WHEN MAX(p.payment_date - o.order_date) > 300 THEN 30
                 WHEN MAX(p.payment_date - o.order_date) > 180 THEN 20
                 WHEN MAX(p.payment_date - o.order_date) > 90 THEN 10
                 ELSE 0 END +
            CASE WHEN SYSDATE - MAX(p.payment_date) > 365 THEN 30
                 WHEN SYSDATE - MAX(p.payment_date) > 180 THEN 20
                 WHEN SYSDATE - MAX(p.payment_date) > 90 THEN 10
                 ELSE 0 END, 0) >= 40 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_category
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name;

COMMENT ON TABLE vw_customer_risk_scores IS 'Customer risk scoring (0-100 scale) based on payment behavior';

-- ============================================================================
-- VIEW 7: SEGMENT SUMMARY STATISTICS
-- ============================================================================
CREATE OR REPLACE VIEW vw_segment_summary_statistics AS
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        COUNT(p.payment_id) as total_payments,
        SUM(p.amount) as total_revenue,
        AVG(p.payment_date - o.order_date) as avg_payment_delay,
        CASE 
            WHEN AVG(p.payment_date - o.order_date) < -30 THEN 'Very Early Payer'
            WHEN AVG(p.payment_date - o.order_date) < 0 THEN 'Early Payer'
            WHEN AVG(p.payment_date - o.order_date) <= 30 THEN 'On-Time Payer'
            WHEN AVG(p.payment_date - o.order_date) <= 90 THEN 'Late Payer'
            ELSE 'Very Late Payer'
        END as payment_category
    FROM customers_clean c
    JOIN orders_clean o ON c.customer_id = o.customer_id
    JOIN payments_clean p ON o.order_id = p.order_id
    GROUP BY c.customer_id
)
SELECT 
    payment_category,
    COUNT(customer_id) as customer_count,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER (), 2) as percentage_of_customers,
    ROUND(AVG(total_payments), 2) as avg_payments_per_customer,
    ROUND(AVG(total_revenue), 2) as avg_revenue_per_customer,
    ROUND(SUM(total_revenue), 2) as total_segment_revenue,
    ROUND(AVG(avg_payment_delay), 2) as avg_delay_days
FROM customer_segments
GROUP BY payment_category
ORDER BY 
    CASE payment_category
        WHEN 'Very Early Payer' THEN 1
        WHEN 'Early Payer' THEN 2
        WHEN 'On-Time Payer' THEN 3
        WHEN 'Late Payer' THEN 4
        WHEN 'Very Late Payer' THEN 5
    END;

COMMENT ON TABLE vw_segment_summary_statistics IS 'Aggregated statistics by payment behavior segment';

-- ============================================================================
-- VIEW 8: PAYMENT METHOD ANALYSIS BY SEGMENT
-- ============================================================================
CREATE OR REPLACE VIEW vw_payment_method_by_segment AS
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        AVG(p.payment_date - o.order_date) as avg_payment_delay,
        CASE 
            WHEN AVG(p.payment_date - o.order_date) < 0 THEN 'Early Payer'
            WHEN AVG(p.payment_date - o.order_date) <= 30 THEN 'On-Time Payer'
            WHEN AVG(p.payment_date - o.order_date) <= 90 THEN 'Late Payer'
            ELSE 'Very Late Payer'
        END as payment_category
    FROM customers_clean c
    JOIN orders_clean o ON c.customer_id = o.customer_id
    JOIN payments_clean p ON o.order_id = p.order_id
    GROUP BY c.customer_id
)
SELECT 
    cs.payment_category,
    p.method as payment_method,
    COUNT(*) as transaction_count,
    ROUND(SUM(p.amount), 2) as total_amount,
    ROUND(AVG(p.amount), 2) as avg_transaction_amount
FROM customer_segments cs
JOIN orders_clean o ON cs.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY cs.payment_category, p.method
ORDER BY cs.payment_category, transaction_count DESC;

COMMENT ON TABLE vw_payment_method_by_segment IS 'Preferred payment methods by customer behavior segment';

-- ============================================================================
-- VIEW 9: MONTHLY PAYMENT TRENDS
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_payment_trends AS
SELECT 
    TO_CHAR(p.payment_date, 'YYYY-MM') as payment_month,
    COUNT(DISTINCT c.customer_id) as active_customers,
    COUNT(p.payment_id) as total_payments,
    ROUND(SUM(p.amount), 2) as total_revenue,
    ROUND(AVG(p.payment_date - o.order_date), 2) as avg_payment_delay,
    SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) as late_payments,
    ROUND(SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(p.payment_id), 2) as late_payment_percentage
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY TO_CHAR(p.payment_date, 'YYYY-MM')
ORDER BY payment_month;

COMMENT ON TABLE vw_monthly_payment_trends IS 'Monthly trends in payment behavior and revenue';

-- ============================================================================
-- EXECUTION CONFIRMATION
-- ============================================================================
-- After running this script, verify views were created:
-- SELECT view_name, comments FROM user_tab_comments WHERE table_type = 'VIEW' AND view_name LIKE 'VW_CUSTOMER%' OR view_name LIKE 'VW_PAYMENT%' OR view_name LIKE 'VW_SEGMENT%' OR view_name LIKE 'VW_MONTHLY%' ORDER BY view_name;

-- To drop all views if needed:
-- DROP VIEW vw_customer_payment_metrics;
-- DROP VIEW vw_payment_delay_analysis;
-- DROP VIEW vw_late_payment_statistics;
-- DROP VIEW vw_customer_quartile_segments;
-- DROP VIEW vw_customer_segments_comprehensive;
-- DROP VIEW vw_customer_risk_scores;
-- DROP VIEW vw_segment_summary_statistics;
-- DROP VIEW vw_payment_method_by_segment;
-- DROP VIEW vw_monthly_payment_trends;
