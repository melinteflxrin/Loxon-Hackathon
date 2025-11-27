# Loxon-Hackathon
## Customer Payment Behavior Segmentation & Fraud Detection

---

## Key Files

### `/src/` - Python Scripts

**AI Pipeline (Run in Order):**
1. `prepare_data.py` - Loads CSVs, merges tables, creates customer summary
2. `feature_engineering.py` - Calculates payment behavior features (delays, frequency, amounts)
3. `customer_segmentation.py` - K-means clustering into 4 segments
4. `predictive_modeling.py` - Trains Random Forest classifier (92.86% accuracy)
5. `anomaly_fraud_detection.py` - Detects 11 fraudulent transactions, 7 risky customers
6. `dashboard.py` - Interactive Streamlit dashboard with all visualizations

**Presentation Tools:**
- `sql_results_visualizer.py` - Generates interactive charts from SQL query results
- `sql_table_formatter.py` - Creates styled HTML tables for PowerPoint screenshots

### `/sql/` - Oracle Database Scripts
- `profiling.sql` - Data exploration queries to understand patterns and quality issues
- `cleansing.sql` - Creates clean DW tables with quality flags, normalizes data
- `01_create_consistency_log_table.sql` - Creates validation table with 31 data quality flags
- `02_validate_and_populate_log.sql` - Validates data, logs 1,228 issues
- `03_query_consistency_log.sql` - 9 analytical queries for data quality insights
- `04_customer_payment_behavior_segmentation.sql` - Creates 7 views (requires CREATE VIEW privilege)
- `04b_customer_payment_behavior_queries.sql` - 7 standalone queries: behavior segments, revenue quartiles, top/risky customers

### 📊 Presentation Guide
See `SQL_RESULTS_PRESENTATION_GUIDE.md` for 5 ways to visualize SQL results in your presentation