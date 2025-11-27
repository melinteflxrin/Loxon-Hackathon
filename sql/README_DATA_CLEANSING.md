# Data Cleansing Scripts - Oracle 19c

Comprehensive SQL scripts for cleaning raw staging tables (`ST_*`) into clean data warehouse tables (`DW_*`).

## 📋 Table of Contents

- [Overview](#overview)
- [Source Data Structure](#source-data-structure)
- [Target Data Structure](#target-data-structure)
- [Cleansing Rules](#cleansing-rules)
- [Execution Order](#execution-order)
- [Data Quality Issues Handled](#data-quality-issues-handled)

---

## 🎯 Overview

These scripts transform messy, VARCHAR2-only staging tables into properly typed, normalized data warehouse tables suitable for analytics and ML modeling.

**Key Features:**
- ✅ Type conversion (VARCHAR2 → DATE, NUMBER)
- ✅ Data validation and quality flags
- ✅ Duplicate detection and handling
- ✅ Referential integrity enforcement
- ✅ Comprehensive data quality reporting

---

## 📊 Source Data Structure

### Staging Tables (All VARCHAR2)

**`ST_CUSTOMERS`** (Dimension)
- `customer_id` - Mixed formats (CUST1020, 1688, d766ec31)
- `full_name` - Various formats, some with `/` separators
- `email` - Multiple emails, invalid formats, "not-an-email"
- `phone` - Inconsistent formats with prefixes/extensions
- `reg_date` - 10+ date formats, "unknown", "N/A"

**`ST_ORDERS`** (Fact 1)
- `order_id` - Mixed formats (ORD2159, 2865, 9ad1b747-b)
- `customer_id` - NULL, empty, invalid references
- `order_date` - 10+ date formats, "unknown", "today", "yesterday"
- `amount` - Negative values, "N/A", embedded currency ("3081.69 USD")
- `currency` - USD, US$, EUR, EURO, HUF, empty

**`ST_PAYMENTS`** (Fact 2)
- `payment_id` - Duplicates exist (PAY3191, PAY3288 appear multiple times)
- `order_id` - NULL, empty, invalid references
- `payment_date` - 10+ date formats, "N/A"
- `amount` - Negative values, "N/A", embedded currency
- `method` - Card, CARD, cArD, PayPal, pay_pal, bank_transfer, bank-tf, cash

---

## 🏗️ Target Data Structure

### Data Warehouse Tables (Properly Typed)

**`DW_CUSTOMERS`**
```sql
customer_id NUMBER PRIMARY KEY          -- Normalized numeric ID
customer_id_raw VARCHAR2(50)            -- Original ID for reference
first_name VARCHAR2(100)                -- Extracted from full_name
last_name VARCHAR2(100)                 -- Extracted from full_name
full_name VARCHAR2(200)                 -- Cleaned full name
email VARCHAR2(200)                     -- Validated email
email_valid NUMBER(1)                   -- 1=valid, 0=invalid
phone VARCHAR2(20)                      -- Raw phone
phone_cleaned VARCHAR2(20)              -- Digits only, validated length
reg_date DATE                           -- Parsed registration date
reg_date_raw VARCHAR2(50)               -- Original date string
```

**`DW_ORDERS`**
```sql
order_id VARCHAR2(50) PRIMARY KEY
customer_id NUMBER FK → dw_customers
customer_id_raw VARCHAR2(50)
customer_valid NUMBER(1)                -- 1=valid ref, 0=invalid
order_date DATE
order_date_raw VARCHAR2(50)
amount NUMBER(12,2)                     -- Absolute value
amount_raw VARCHAR2(50)
currency CHAR(3)                        -- USD, EUR, HUF
currency_raw VARCHAR2(20)
is_refund NUMBER(1)                     -- 1=negative, 0=positive
```

**`DW_PAYMENTS`**
```sql
payment_id VARCHAR2(50) PRIMARY KEY
order_id VARCHAR2(50) FK → dw_orders
order_valid NUMBER(1)                   -- 1=valid ref, 0=invalid
payment_date DATE
payment_date_raw VARCHAR2(50)
amount NUMBER(12,2)                     -- Absolute value
amount_raw VARCHAR2(50)
method VARCHAR2(20)                     -- Normalized method
method_raw VARCHAR2(50)
is_duplicate NUMBER(1)                  -- 1=duplicate, 0=unique
```

---

## 🔧 Cleansing Rules

### Customer Data
- **customer_id**: Extract numbers, hash if alphanumeric
- **full_name**: Split on space or `/`, clean special characters
- **email**: Validate regex `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
- **phone**: Remove non-digits, validate length (7-15 digits)
- **reg_date**: Try 8 date formats, mark "unknown"/"N/A" as NULL

### Order Data
- **order_date**: Try 8 date formats, mark special values as NULL
- **amount**: Extract numbers, take absolute value, mark negatives as refunds
- **currency**: Map USD/US$/EUR/EURO/HUF using lookup table
- **customer_id**: Validate foreign key, flag invalid references

### Payment Data
- **payment_date**: Try 8 date formats
- **amount**: Take absolute value (payments always positive)
- **method**: Normalize to: Card, PayPal, Bank Transfer, Cash
- **order_id**: Validate foreign key, flag orphan payments
- **duplicates**: Detect, keep best record (valid order, recent date, non-null amount)

---

## ▶️ Execution Order

Run scripts in **exact order**:

```bash
# 1. Setup tables, mappings, functions
@01_master_setup.sql

# 2. Clean customers (no dependencies)
@02_cleanse_customers.sql

# 3. Clean orders (depends on customers)
@03_cleanse_orders.sql

# 4. Clean payments (depends on orders)
@04_cleanse_payments.sql

# 5. Generate quality report
@05_data_quality_report.sql
```

### Detailed Steps

```sql
-- Connect to Oracle 19c
sqlplus username/password@database

-- Execute in order
@/path/to/01_master_setup.sql
@/path/to/02_cleanse_customers.sql
@/path/to/03_cleanse_orders.sql
@/path/to/04_cleanse_payments.sql
@/path/to/05_data_quality_report.sql
```

---

## 🐛 Data Quality Issues Handled

### Issues Found in Source Data

| Issue | Count | Resolution |
|-------|-------|------------|
| **Customers** | | |
| Invalid email formats | ~20% | Flagged with `email_valid=0` |
| "not-an-email" placeholders | ~15 | Set to NULL, flagged invalid |
| Multiple emails (comma-separated) | ~5 | Took first valid email |
| Phone with text ("phone:xxx") | ~30 | Extracted digits only |
| Invalid date formats | ~3% | Set to NULL, kept raw value |
| **Orders** | | |
| NULL/empty customer_id | ~25% | Flagged `customer_valid=0` |
| Negative amounts (refunds) | ~8% | Took absolute, flagged `is_refund=1` |
| "N/A" amounts | ~12 | Set to NULL |
| Embedded currency in amount | ~20 | Extracted both parts |
| Duplicate order_ids | ~15 | Kept best record (valid customer, recent) |
| Invalid dates ("today", "unknown") | ~5% | Set to NULL |
| **Payments** | | |
| Duplicate payment_ids | ~8 | Kept best record (valid order) |
| NULL/empty order_id | ~30% | Flagged `order_valid=0` |
| Negative amounts | ~5% | Took absolute value |
| "N/A" amounts | ~8 | Set to NULL |
| Mixed case methods | All | Normalized to standard names |

---

## 📈 Expected Output

### Data Quality Metrics

After running all scripts, expect:

```
CUSTOMERS:
  Total: ~100 customers
  Valid emails: ~80%
  Valid phones: ~70%
  Valid dates: ~97%

ORDERS:
  Total: ~500 orders
  Valid customer refs: ~75%
  Valid dates: ~95%
  Valid amounts: ~88%
  Refunds: ~8%

PAYMENTS:
  Total: ~700 payments
  Valid order refs: ~70%
  Valid dates: ~92%
  Valid amounts: ~92%
  Duplicates resolved: ~8%
```

---

## 🎯 Next Steps

After cleansing:

1. **Export cleaned data**:
   ```sql
   -- Export to CSV for Python analysis
   SELECT * FROM dw_customers;
   SELECT * FROM dw_orders;
   SELECT * FROM dw_payments;
   ```

2. **Create analytical views**:
   ```sql
   @create_views.sql
   ```

3. **Run Python AI analysis**:
   - Use cleaned `dw_*` tables as input
   - No further data cleaning needed
   - All dates are proper DATE type
   - All amounts are proper NUMBER type
   - All flags indicate data quality issues

---

## 🔍 Validation Queries

Check data quality:

```sql
-- Customers with invalid emails
SELECT * FROM dw_customers WHERE email_valid = 0;

-- Orders without customers
SELECT * FROM dw_orders WHERE customer_valid = 0;

-- Orphan payments
SELECT * FROM dw_payments WHERE order_valid = 0;

-- Refund orders
SELECT * FROM dw_orders WHERE is_refund = 1;

-- Revenue by currency
SELECT currency, COUNT(*), SUM(amount) 
FROM dw_orders 
GROUP BY currency;
```

---

## 📝 Notes

- **Idempotent**: Scripts can be re-run (tables are dropped and recreated)
- **Production Use**: Remove `DROP TABLE` statements for production
- **Performance**: Indexes created for foreign keys and date ranges
- **Audit Trail**: Raw values preserved in `*_raw` columns
- **Quality Flags**: Use flags for filtering or reporting data issues

---

## 👥 Authors

Loxon Hackathon Team
Date: November 2025
