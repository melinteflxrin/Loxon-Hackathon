-- CUSTOMER PAYMENT BEHAVIOR SEGMENTATION - SQL QUERIES

-- 1. BASIC CUSTOMER PAYMENT METRICS

-- Calculate key payment metrics per customer
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(p.payment_id) as total_payments,
    SUM(p.amount) as total_revenue,
    AVG(p.amount) as avg_payment_amount,
    MIN(p.payment_date) as first_payment_date,
    MAX(p.payment_date) as last_payment_date,
    SYSDATE - MAX(p.payment_date) as days_since_last_payment
FROM customers_clean c
LEFT JOIN orders_clean o ON c.customer_id = o.customer_id
LEFT JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY total_revenue DESC;


-- 2. PAYMENT DELAY ANALYSIS

-- Calculate payment delays (payment_date - order_date)
-- Positive = late payment, Negative = early payment, 0 = on-time
SELECT 
    c.customer_id,
    c.full_name,
    o.order_id,
    o.order_date,
    p.payment_date,
    p.payment_date - o.order_date as payment_delay_days,
    p.amount,
    p.method,
    CASE 
        WHEN p.payment_date - o.order_date < -30 THEN 'Very Early'
        WHEN p.payment_date - o.order_date < 0 THEN 'Early'
        WHEN p.payment_date - o.order_date <= 30 THEN 'On-Time'
        WHEN p.payment_date - o.order_date <= 90 THEN 'Late'
        ELSE 'Very Late'
    END as payment_status
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
ORDER BY c.customer_id, o.order_date;


-- 3. AVERAGE PAYMENT DELAY PER CUSTOMER (KPI in requirements)

SELECT 
    c.customer_id,
    c.full_name,
    COUNT(p.payment_id) as total_payments,
    AVG(p.payment_date - o.order_date) as avg_payment_delay_days,
    MIN(p.payment_date - o.order_date) as min_delay_days,
    MAX(p.payment_date - o.order_date) as max_delay_days,
    STDDEV(p.payment_date - o.order_date) as stddev_delay_days,
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
ORDER BY avg_payment_delay_days DESC;


-- 4. COUNT OF LATE PAYMENTS VS TOTAL PAYMENTS (Required KPI)

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
HAVING COUNT(p.payment_id) > 0
ORDER BY late_payment_percentage DESC;


-- 5. QUARTILE SEGMENTATION USING NTILE (Required KPI)

-- Segment customers into 4 quartiles based on average payment delay
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
    avg_payment_delay,
    total_payments,
    total_revenue,
    NTILE(4) OVER (ORDER BY avg_payment_delay) as delay_quartile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 1 THEN 'Q1 - Best Payers (Earliest)'
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 2 THEN 'Q2 - Good Payers'
        WHEN NTILE(4) OVER (ORDER BY avg_payment_delay) = 3 THEN 'Q3 - Moderate Payers'
        ELSE 'Q4 - Worst Payers (Latest)'
    END as quartile_description
FROM customer_delays
ORDER BY delay_quartile, avg_payment_delay;


-- 6. COMPREHENSIVE PAYMENT BEHAVIOR SEGMENTATION

-- Combine all metrics with multiple segmentation approaches
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
    total_revenue,
    avg_payment_amount,
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
WHERE total_payments > 0
ORDER BY total_revenue DESC, avg_payment_delay;


-- 7. SUMMARY STATISTICS BY SEGMENT

-- Aggregate metrics for each payment behavior category
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



-- 8. PAYMENT METHOD ANALYSIS BY SEGMENT

-- Analyze preferred payment methods for each behavior segment
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
    SUM(p.amount) as total_amount,
    ROUND(AVG(p.amount), 2) as avg_transaction_amount
FROM customer_segments cs
JOIN orders_clean o ON cs.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY cs.payment_category, p.method
ORDER BY cs.payment_category, transaction_count DESC;



-- 9. CUSTOMER RISK SCORING
-- Calculate a risk score based on multiple factors
SELECT 
    c.customer_id,
    c.full_name,
    AVG(p.payment_date - o.order_date) as avg_delay,
    MAX(p.payment_date - o.order_date) as max_delay,
    SYSDATE - MAX(p.payment_date) as recency_days,
    COUNT(p.payment_id) as total_payments,
    SUM(p.amount) as total_revenue,
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
GROUP BY c.customer_id, c.full_name
ORDER BY risk_score DESC;



-- 10. TREND ANALYSIS - PAYMENT BEHAVIOR OVER TIME

-- Analyze how payment behavior changes over time (monthly)
SELECT 
    TO_CHAR(p.payment_date, 'YYYY-MM') as payment_month,
    COUNT(DISTINCT c.customer_id) as active_customers,
    COUNT(p.payment_id) as total_payments,
    SUM(p.amount) as total_revenue,
    AVG(p.payment_date - o.order_date) as avg_payment_delay,
    SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) as late_payments,
    ROUND(SUM(CASE WHEN p.payment_date - o.order_date > 30 THEN 1 ELSE 0 END) * 100.0 / COUNT(p.payment_id), 2) as late_payment_percentage
FROM customers_clean c
JOIN orders_clean o ON c.customer_id = o.customer_id
JOIN payments_clean p ON o.order_id = p.order_id
GROUP BY TO_CHAR(p.payment_date, 'YYYY-MM')
ORDER BY payment_month;
