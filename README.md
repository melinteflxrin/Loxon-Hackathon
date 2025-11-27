# Loxon-Hackathon
## Customer Payment Behavior Segmentation & Fraud Detection

---

## Key Files

### `/src/` - Python Scripts (Run in Order)
1. `prepare_data.py` - Loads CSVs, merges tables, creates customer summary
2. `feature_engineering.py` - Calculates payment behavior features (delays, frequency, amounts)
3. `customer_segmentation.py` - K-means clustering into 4 segments
4. `predictive_modeling.py` - Trains Random Forest classifier (92.86% accuracy)
5. `anomaly_fraud_detection.py` - Detects 11 fraudulent transactions, 7 risky customers
6. `dashboard.py` - Interactive Streamlit dashboard with all visualizations

### `/sql/` - Oracle Database Scripts
- `profiling.sql` - Data exploration queries to understand patterns and quality issues
- `cleansing.sql` - Creates clean DW tables with quality flags, normalizes data
- `01_create_consistency_log_table.sql` - Creates validation table with 31 data quality flags
- `02_validate_and_populate_log.sql` - Validates data, logs 1,228 issues
- `03_query_consistency_log.sql` - 9 analytical queries for data quality insights