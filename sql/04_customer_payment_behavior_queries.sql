-- =====================================================================
-- Customer Payment Behavior Segmentation
-- =====================================================================


-- =====================================================================
-- QUERY 1: Customer Payment Behavior Summary
-- =====================================================================
-- Shows comprehensive payment statistics per customer

WITH customer_payment_details AS (
    -- Calculate payment-level metrics
    SELECT 
        c.customer_id_norm,
        c.full_name_clean,
        c.email_clean,
        o.order_id_clean,
        o.order_date_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        p.payment_method_clean,
        -- Calculate payment delay in days (payment_date - order_date)
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days,
        -- Classify individual payment timing
        CASE
            WHEN p.payment_date_clean IS NULL THEN 'Never Paid'
            WHEN (p.payment_date_clean - o.order_date_clean) < 0 THEN 'Early'
            WHEN (p.payment_date_clean - o.order_date_clean) BETWEEN 0 AND 30 THEN 'On-Time'
            WHEN (p.payment_date_clean - o.order_date_clean) > 30 THEN 'Late'
            ELSE 'Unknown'
        END AS payment_timing_category
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
),

customer_aggregates AS (
    -- Aggregate to customer level
    SELECT
        customer_id_norm,
        full_name_clean,
        email_clean,
        -- Revenue metrics
        SUM(order_amount) AS total_order_value,
        SUM(payment_amount) AS total_paid_amount,
        COUNT(DISTINCT order_id_clean) AS total_orders,
        COUNT(payment_id_clean) AS total_payments,
        -- Payment behavior metrics
        COUNT(CASE WHEN payment_timing_category = 'Early' THEN 1 END) AS early_payments,
        COUNT(CASE WHEN payment_timing_category = 'On-Time' THEN 1 END) AS ontime_payments,
        COUNT(CASE WHEN payment_timing_category = 'Late' THEN 1 END) AS late_payments,
        COUNT(CASE WHEN payment_timing_category = 'Never Paid' THEN 1 END) AS unpaid_orders,
        -- Delay statistics
        AVG(payment_delay_days) AS avg_payment_delay_days,
        MIN(payment_delay_days) AS min_payment_delay_days,
        MAX(payment_delay_days) AS max_payment_delay_days,
        STDDEV(payment_delay_days) AS stddev_payment_delay_days
    FROM customer_payment_details
    GROUP BY customer_id_norm, full_name_clean, email_clean
),

customer_segmentation AS (
    -- Add segmentation and revenue quartiles
    SELECT
        customer_id_norm,
        full_name_clean,
        email_clean,
        total_order_value,
        total_paid_amount,
        total_orders,
        total_payments,
        early_payments,
        ontime_payments,
        late_payments,
        unpaid_orders,
        avg_payment_delay_days,
        min_payment_delay_days,
        max_payment_delay_days,
        stddev_payment_delay_days,
        -- Calculate payment ratios
        CASE 
            WHEN total_orders > 0 
            THEN ROUND((total_payments * 100.0 / total_orders), 2)
            ELSE 0
        END AS payment_completion_rate,
        CASE 
            WHEN total_payments > 0 
            THEN ROUND((late_payments * 100.0 / total_payments), 2)
            ELSE 0
        END AS late_payment_rate,
        -- Overall payment behavior classification
        CASE
            WHEN total_payments = 0 THEN 'Non-Payer'
            WHEN late_payments > ontime_payments + early_payments THEN 'Chronic Late Payer'
            WHEN late_payments * 1.0 / total_payments > 0.3 THEN 'Frequent Late Payer'
            WHEN avg_payment_delay_days > 30 THEN 'Occasional Late Payer'
            WHEN avg_payment_delay_days <= 0 THEN 'Early Payer'
            ELSE 'On-Time Payer'
        END AS payment_behavior_segment,
        -- Revenue quartile (1 = lowest revenue, 4 = highest revenue)
        NTILE(4) OVER (ORDER BY total_paid_amount NULLS FIRST) AS revenue_quartile
    FROM customer_aggregates
)

SELECT
    customer_id_norm AS "Customer ID",
    full_name_clean AS "Customer Name",
    email_clean AS "Email",
    total_order_value AS "Total Orders Value (HUF)",
    total_paid_amount AS "Total Paid (HUF)",
    total_orders AS "# Orders",
    total_payments AS "# Payments",
    early_payments AS "Early Payments",
    ontime_payments AS "On-Time Payments",
    late_payments AS "Late Payments",
    unpaid_orders AS "Unpaid Orders",
    payment_completion_rate AS "Payment Completion %",
    late_payment_rate AS "Late Payment %",
    ROUND(avg_payment_delay_days, 1) AS "Avg Delay (Days)",
    ROUND(min_payment_delay_days, 1) AS "Min Delay (Days)",
    ROUND(max_payment_delay_days, 1) AS "Max Delay (Days)",
    payment_behavior_segment AS "Behavior Segment",
    revenue_quartile AS "Revenue Quartile (1-4)"
FROM customer_segmentation
ORDER BY total_paid_amount DESC NULLS LAST, avg_payment_delay_days DESC;


-- =====================================================================
-- QUERY 2: Payment Behavior Segment Summary
-- =====================================================================
-- Aggregates customers by behavior segment

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        c.full_name_clean,
        o.order_id_clean,
        o.order_date_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days,
        CASE
            WHEN p.payment_date_clean IS NULL THEN 'Never Paid'
            WHEN (p.payment_date_clean - o.order_date_clean) < 0 THEN 'Early'
            WHEN (p.payment_date_clean - o.order_date_clean) BETWEEN 0 AND 30 THEN 'On-Time'
            WHEN (p.payment_date_clean - o.order_date_clean) > 30 THEN 'Late'
            ELSE 'Unknown'
        END AS payment_timing_category
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
),

customer_aggregates AS (
    SELECT
        customer_id_norm,
        SUM(payment_amount) AS total_paid_amount,
        COUNT(DISTINCT order_id_clean) AS total_orders,
        COUNT(payment_id_clean) AS total_payments,
        COUNT(CASE WHEN payment_timing_category = 'Early' THEN 1 END) AS early_payments,
        COUNT(CASE WHEN payment_timing_category = 'On-Time' THEN 1 END) AS ontime_payments,
        COUNT(CASE WHEN payment_timing_category = 'Late' THEN 1 END) AS late_payments,
        AVG(payment_delay_days) AS avg_payment_delay_days
    FROM customer_payment_details
    GROUP BY customer_id_norm
),

customer_segmentation AS (
    SELECT
        customer_id_norm,
        total_paid_amount,
        total_orders,
        total_payments,
        avg_payment_delay_days,
        CASE
            WHEN total_payments = 0 THEN 'Non-Payer'
            WHEN late_payments > ontime_payments + early_payments THEN 'Chronic Late Payer'
            WHEN late_payments * 1.0 / total_payments > 0.3 THEN 'Frequent Late Payer'
            WHEN avg_payment_delay_days > 30 THEN 'Occasional Late Payer'
            WHEN avg_payment_delay_days <= 0 THEN 'Early Payer'
            ELSE 'On-Time Payer'
        END AS payment_behavior_segment
    FROM customer_aggregates
)

SELECT
    payment_behavior_segment AS "Payment Behavior Segment",
    COUNT(DISTINCT customer_id_norm) AS "# Customers",
    ROUND(COUNT(DISTINCT customer_id_norm) * 100.0 / SUM(COUNT(DISTINCT customer_id_norm)) OVER (), 2) AS "% of Customers",
    SUM(total_paid_amount) AS "Total Revenue (HUF)",
    ROUND(AVG(total_paid_amount), 2) AS "Avg Revenue per Customer (HUF)",
    ROUND(AVG(avg_payment_delay_days), 1) AS "Avg Payment Delay (Days)",
    SUM(total_orders) AS "Total Orders",
    SUM(total_payments) AS "Total Payments"
FROM customer_segmentation
GROUP BY payment_behavior_segment
ORDER BY SUM(total_paid_amount) DESC;


-- =====================================================================
-- QUERY 3: Revenue Quartile Analysis
-- =====================================================================

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        o.order_id_clean,
        o.order_date_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
),

customer_aggregates AS (
    SELECT
        customer_id_norm,
        SUM(payment_amount) AS total_paid_amount,
        COUNT(payment_id_clean) AS total_payments,
        AVG(payment_delay_days) AS avg_payment_delay_days,
        NTILE(4) OVER (ORDER BY SUM(payment_amount) NULLS FIRST) AS revenue_quartile
    FROM customer_payment_details
    GROUP BY customer_id_norm
)

SELECT
    revenue_quartile AS "Revenue Quartile",
    CASE revenue_quartile
        WHEN 1 THEN 'Q1 (Lowest 25%)'
        WHEN 2 THEN 'Q2 (25-50%)'
        WHEN 3 THEN 'Q3 (50-75%)'
        WHEN 4 THEN 'Q4 (Top 25%)'
    END AS "Quartile Description",
    COUNT(DISTINCT customer_id_norm) AS "# Customers",
    SUM(total_paid_amount) AS "Total Revenue (HUF)",
    ROUND(AVG(total_paid_amount), 2) AS "Avg Revenue per Customer (HUF)",
    MIN(total_paid_amount) AS "Min Revenue (HUF)",
    MAX(total_paid_amount) AS "Max Revenue (HUF)",
    ROUND(AVG(avg_payment_delay_days), 1) AS "Avg Payment Delay (Days)",
    SUM(total_payments) AS "Total Payments"
FROM customer_aggregates
GROUP BY revenue_quartile
ORDER BY revenue_quartile;


-- =====================================================================
-- QUERY 4: Top 10 Best Customers
-- =====================================================================

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        c.full_name_clean,
        c.email_clean,
        o.order_id_clean,
        o.order_date_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
),

customer_aggregates AS (
    SELECT
        customer_id_norm,
        full_name_clean,
        email_clean,
        SUM(payment_amount) AS total_paid_amount,
        COUNT(payment_id_clean) AS total_payments,
        AVG(payment_delay_days) AS avg_payment_delay_days
    FROM customer_payment_details
    GROUP BY customer_id_norm, full_name_clean, email_clean
)

SELECT
    ROWNUM AS "Rank",
    customer_id_norm AS "Customer ID",
    full_name_clean AS "Customer Name",
    email_clean AS "Email",
    total_paid_amount AS "Total Revenue (HUF)",
    total_payments AS "# Payments",
    ROUND(avg_payment_delay_days, 1) AS "Avg Payment Delay (Days)"
FROM customer_aggregates
WHERE total_payments > 0
ORDER BY total_paid_amount DESC, avg_payment_delay_days ASC
FETCH FIRST 10 ROWS ONLY;


-- =====================================================================
-- QUERY 5: Top 10 Risky Customers
-- =====================================================================

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        c.full_name_clean,
        c.email_clean,
        o.order_id_clean,
        o.order_date_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days,
        CASE
            WHEN p.payment_date_clean IS NULL THEN 'Never Paid'
            WHEN (p.payment_date_clean - o.order_date_clean) > 30 THEN 'Late'
            ELSE 'On-Time/Early'
        END AS payment_timing_category
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
),

customer_aggregates AS (
    SELECT
        customer_id_norm,
        full_name_clean,
        email_clean,
        SUM(payment_amount) AS total_paid_amount,
        COUNT(payment_id_clean) AS total_payments,
        COUNT(CASE WHEN payment_timing_category = 'Late' THEN 1 END) AS late_payments,
        COUNT(CASE WHEN payment_timing_category = 'Never Paid' THEN 1 END) AS unpaid_orders,
        AVG(payment_delay_days) AS avg_payment_delay_days,
        MAX(payment_delay_days) AS max_payment_delay_days
    FROM customer_payment_details
    GROUP BY customer_id_norm, full_name_clean, email_clean
)

SELECT
    ROWNUM AS "Rank",
    customer_id_norm AS "Customer ID",
    full_name_clean AS "Customer Name",
    email_clean AS "Email",
    NVL(total_paid_amount, 0) AS "Total Revenue (HUF)",
    total_payments AS "# Payments",
    late_payments AS "# Late Payments",
    unpaid_orders AS "# Unpaid Orders",
    ROUND(avg_payment_delay_days, 1) AS "Avg Payment Delay (Days)",
    ROUND(max_payment_delay_days, 1) AS "Max Payment Delay (Days)"
FROM customer_aggregates
WHERE total_payments > 0 OR unpaid_orders > 0
ORDER BY avg_payment_delay_days DESC NULLS LAST, late_payments DESC, unpaid_orders DESC
FETCH FIRST 10 ROWS ONLY;


-- =====================================================================
-- QUERY 6: Payment Delay Distribution (Histogram)
-- =====================================================================

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        p.payment_date_clean,
        o.order_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
      AND p.payment_date_clean IS NOT NULL
),

delay_buckets AS (
    SELECT
        customer_id_norm,
        payment_amount,
        payment_delay_days,
        CASE
            WHEN payment_delay_days < 0 THEN 'Early (< 0 days)'
            WHEN payment_delay_days BETWEEN 0 AND 7 THEN '0-7 days'
            WHEN payment_delay_days BETWEEN 8 AND 30 THEN '8-30 days'
            WHEN payment_delay_days BETWEEN 31 AND 60 THEN '31-60 days'
            WHEN payment_delay_days BETWEEN 61 AND 90 THEN '61-90 days'
            WHEN payment_delay_days BETWEEN 91 AND 180 THEN '91-180 days'
            WHEN payment_delay_days BETWEEN 181 AND 365 THEN '181-365 days'
            WHEN payment_delay_days > 365 THEN 'Over 1 year'
            ELSE 'Unknown'
        END AS delay_bucket
    FROM customer_payment_details
)

SELECT
    delay_bucket AS "Payment Delay Range",
    COUNT(DISTINCT customer_id_norm) AS "# Customers",
    COUNT(*) AS "# Payments",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS "% of Payments",
    SUM(payment_amount) AS "Total Revenue (HUF)",
    ROUND(AVG(payment_delay_days), 1) AS "Avg Delay in Bucket (Days)"
FROM delay_buckets
GROUP BY delay_bucket
ORDER BY 
    CASE delay_bucket
        WHEN 'Early (< 0 days)' THEN 1
        WHEN '0-7 days' THEN 2
        WHEN '8-30 days' THEN 3
        WHEN '31-60 days' THEN 4
        WHEN '61-90 days' THEN 5
        WHEN '91-180 days' THEN 6
        WHEN '181-365 days' THEN 7
        WHEN 'Over 1 year' THEN 8
        ELSE 9
    END;


-- =====================================================================
-- QUERY 7: Executive Summary - Key Metrics
-- =====================================================================

WITH customer_payment_details AS (
    SELECT 
        c.customer_id_norm,
        o.order_id_clean,
        o.amount_num AS order_amount,
        p.payment_id_clean,
        p.payment_date_clean,
        p.amount_num AS payment_amount,
        CASE 
            WHEN p.payment_date_clean IS NOT NULL AND o.order_date_clean IS NOT NULL
            THEN p.payment_date_clean - o.order_date_clean
            ELSE NULL
        END AS payment_delay_days,
        CASE
            WHEN p.payment_date_clean IS NULL THEN 'Never Paid'
            WHEN (p.payment_date_clean - o.order_date_clean) > 30 THEN 'Late'
            ELSE 'On-Time/Early'
        END AS payment_timing_category
    FROM dw_customers c
    LEFT JOIN dw_orders o ON c.customer_id_norm = o.customer_id_norm
    LEFT JOIN dw_payments p ON o.order_id_clean = TO_CHAR(p.order_id_norm)
    WHERE c.customer_id_norm IS NOT NULL
)

SELECT
    COUNT(DISTINCT customer_id_norm) AS "Total Customers",
    COUNT(DISTINCT order_id_clean) AS "Total Orders",
    COUNT(payment_id_clean) AS "Total Payments",
    COUNT(DISTINCT CASE WHEN payment_id_clean IS NOT NULL THEN customer_id_norm END) AS "Customers Who Paid",
    ROUND(COUNT(payment_id_clean) * 100.0 / NULLIF(COUNT(DISTINCT order_id_clean), 0), 2) AS "Overall Payment Rate %",
    SUM(order_amount) AS "Total Orders Value (HUF)",
    SUM(payment_amount) AS "Total Collected (HUF)",
    ROUND(SUM(payment_amount) * 100.0 / NULLIF(SUM(order_amount), 0), 2) AS "Collection Rate %",
    ROUND(AVG(payment_delay_days), 1) AS "Avg Payment Delay (Days)",
    COUNT(CASE WHEN payment_timing_category = 'Late' THEN 1 END) AS "# Late Payments",
    ROUND(COUNT(CASE WHEN payment_timing_category = 'Late' THEN 1 END) * 100.0 / NULLIF(COUNT(payment_id_clean), 0), 2) AS "Late Payment Rate %",
    COUNT(CASE WHEN payment_timing_category = 'Never Paid' THEN 1 END) AS "# Unpaid Orders"
FROM customer_payment_details;


