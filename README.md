# Loxon-Hackathon
## Customer Payment Behavior Segmentation & Fraud Detection

---

## Key Files

### `/src/` - Python Scripts

**AI Pipeline (Run in Order):**
1. `prepare_data.py` - Loads CSVs, merges customers/orders/payments, creates feature dataset
2. `feature_engineering.py` - Calculates 17 payment behavior features (delays, amounts, frequency, recency)
3. `customer_segmentation.py` - K-means clustering into 4 behavioral segments (VIP, Standard, Problem, Low-Value)
4. `predictive_modeling.py` - Trains Random Forest classifier (92.86% accuracy), exports model + feature importance
5. `anomaly_fraud_detection.py` - Ensemble detection (3 algorithms: Isolation Forest, SVM, Elliptic Envelope) finds 7 anomalous customers + 11 fraudulent transactions
6. `dashboard.py` - Interactive Streamlit dashboard with 4 views: segmentation, fraud detection, combined analysis, segment predictor

**SQL Presentation Tools:**
- `sql_results_visualizer.py` - Generates 5 interactive HTML charts from SQL query CSVs (segment distribution, quartiles, customer comparison, delays, executive summary)
- `sql_table_formatter.py` - Creates 6 styled HTML tables with CSS formatting for PowerPoint screenshots
- `create_sql_vs_ai_comparison.py` - Generates transition slide comparing SQL (278 customers, descriptive) vs AI (66 customers, predictive) capabilities

**Data Generation:**
- `generate_mock_data.py` - Creates synthetic customer/order/payment data for testing

### `/sql/` - Oracle Database Scripts
- `profiling.sql` - Data exploration queries to understand patterns and quality issues
- `cleansing.sql` - Creates clean DW tables with quality flags, normalizes data
- `01_create_consistency_log_table.sql` - Creates validation table with 31 data quality flags
- `02_validate_and_populate_log.sql` - Validates data, logs 1,228 issues
- `03_query_consistency_log.sql` - 9 analytical queries for data quality insights
- `04_customer_payment_behavior_queries.sql` - Created 7 kpis: behavior segments, revenue quartiles, top/risky customers
