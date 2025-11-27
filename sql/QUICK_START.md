# 🚀 Quick Start Guide - Data Cleansing Procedures

## **One-Time Setup** (Run These Once)

Execute these scripts in SQL Developer **in this exact order**:

### Step 1: Initial Setup
```sql
-- Copy-paste and run (F5):
@00_create_consistency_log.sql
@01_master_setup.sql
@06_create_procedures.sql
```

**That's it for setup!** Now everything is stored as procedures in the database.

---

## **Running the Data Cleansing** (Anytime)

After initial setup, you can run the entire pipeline with **ONE simple command**:

```sql
-- Run the complete data cleansing pipeline
EXEC pkg_data_quality.run_full_cleansing;
```

This single command does everything:
1. ✅ Validates raw data → logs issues to `LXN_DATA_CONSISTENCY_LOG`
2. ✅ Cleanses customers → creates `dw_customers`
3. ✅ Cleanses orders → creates `dw_orders`
4. ✅ Cleanses payments → creates `dw_payments`
5. ✅ Generates quality report

---

## **Individual Commands** (Optional)

If you want to run specific steps:

```sql
-- Just validation (check data quality)
EXEC pkg_data_quality.run_validation_only;

-- Just cleansing (skip validation)
EXEC pkg_data_quality.run_cleansing_only;

-- Just the quality report
EXEC pkg_data_quality.show_quality_report;

-- Individual steps
EXEC pkg_data_quality.step1_validate_consistency;
EXEC pkg_data_quality.step2_cleanse_customers;
EXEC pkg_data_quality.step3_cleanse_orders;
EXEC pkg_data_quality.step4_cleanse_payments;
EXEC pkg_data_quality.step5_generate_report;
```

---

## **Viewing Results**

```sql
-- View consistency issues summary
SELECT * FROM vw_consistency_summary;

-- View all logged issues
SELECT * FROM lxn_data_consistency_log;

-- View cleaned data
SELECT * FROM dw_customers;
SELECT * FROM dw_orders;
SELECT * FROM dw_payments;

-- Check record counts
SELECT 'Customers' as table_name, COUNT(*) as records FROM dw_customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM dw_orders
UNION ALL
SELECT 'Payments', COUNT(*) FROM dw_payments;
```

---

## **What Judges/Reviewers Will See**

When anyone opens SQL Developer and connects to your database, they'll see:

### **In the Object Browser:**

```
📁 Packages
  └── PKG_DATA_QUALITY ← Your main package!
  
📁 Tables
  ├── LXN_DATA_CONSISTENCY_LOG
  ├── DW_CUSTOMERS
  ├── DW_ORDERS
  └── DW_PAYMENTS
  
📁 Views
  ├── VW_CONSISTENCY_SUMMARY
  ├── VW_CUSTOMER_PAYMENT_METRICS
  ├── VW_PAYMENT_DELAY_ANALYSIS
  └── ... (all your analytical views)
  
📁 Functions
  ├── EXTRACT_NUMERIC_ID
  ├── IS_VALID_EMAIL
  ├── CLEAN_PHONE
  ├── PARSE_DATE_MULTI
  └── CLEAN_AMOUNT
```

### **To Run Your Work:**

They simply double-click **PKG_DATA_QUALITY** package and click "Run" or type:
```sql
EXEC pkg_data_quality.run_full_cleansing;
```

---

## **For Presentation/Demo:**

Show judges this simple flow:

```sql
-- 1. Show raw data issues
SELECT COUNT(*) as "Total Issues Found" 
FROM lxn_data_consistency_log;

-- 2. Run the cleansing
EXEC pkg_data_quality.run_full_cleansing;

-- 3. Show cleaned data
SELECT COUNT(*) FROM dw_customers;
SELECT COUNT(*) FROM dw_orders;
SELECT COUNT(*) FROM dw_payments;

-- 4. Show quality metrics
SELECT * FROM vw_consistency_summary;
```

**Professional Result**: One simple command runs your entire data pipeline! 🎯

---

## **Benefits of This Approach:**

✅ **Persistent**: Procedures stored in database permanently  
✅ **Visible**: Shows up in SQL Developer's object browser  
✅ **Reusable**: Can be run anytime with one command  
✅ **Professional**: Industry-standard approach  
✅ **Shareable**: Anyone with DB access can run it  
✅ **Documented**: Built-in DBMS_OUTPUT shows progress  

---

## **Troubleshooting:**

If you need to re-create everything:

```sql
-- Drop and recreate package
DROP PACKAGE pkg_data_quality;
@06_create_procedures.sql

-- Clear data and re-run
DELETE FROM lxn_data_consistency_log;
DELETE FROM dw_customers;
DELETE FROM dw_orders;
DELETE FROM dw_payments;
COMMIT;

EXEC pkg_data_quality.run_full_cleansing;
```

That's it! Much cleaner than running 6 separate scripts! 🚀
