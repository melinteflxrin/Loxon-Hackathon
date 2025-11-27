import pandas as pd
import numpy as np
import os

# Get the project root (one level up from src)
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))

# Load actual clean data from CSV files
print("Loading clean customer data...")
customers = pd.read_csv(os.path.join(data_dir, 'clean_customers.csv'))
print("Loading clean orders data...")
orders = pd.read_csv(os.path.join(data_dir, 'clean_orders.csv'))
print("Loading clean payments data...")
payments = pd.read_csv(os.path.join(data_dir, 'clean_payments.csv'))

# Rename columns to match expected format (removing _CLEAN/_NORM suffixes)
customers = customers.rename(columns={
    'CUSTOMER_ID_NORM': 'customer_id',
    'FULL_NAME_CLEAN': 'full_name',
    'EMAIL_CLEAN': 'email',
    'PHONE_CLEAN': 'phone',
    'REG_DATE_CLEAN': 'reg_date',
    'DQ_SCORE': 'dq_score'
})

orders = orders.rename(columns={
    'ORDER_ID_CLEAN': 'order_id',
    'CUSTOMER_ID_NORM': 'customer_id',
    'ORDER_DATE_CLEAN': 'order_date',
    'AMOUNT_NUM': 'amount',
    'CURRENCY_CLEAN': 'currency',
    'DQ_SCORE': 'dq_score'
})

payments = payments.rename(columns={
    'PAYMENT_ID_CLEAN': 'payment_id',
    'ORDER_ID_NORM': 'order_id',
    'PAYMENT_DATE_CLEAN': 'payment_date',
    'AMOUNT_NUM': 'amount',
    'PAYMENT_METHOD_CLEAN': 'method',
    'DQ_SCORE': 'dq_score'
})

# Convert date columns to datetime (DD-MMM-YY format)
print("Converting date formats...")
customers['reg_date'] = pd.to_datetime(customers['reg_date'], format='%d-%b-%y', errors='coerce')
orders['order_date'] = pd.to_datetime(orders['order_date'], format='%d-%b-%y', errors='coerce')
payments['payment_date'] = pd.to_datetime(payments['payment_date'], format='%d-%b-%y', errors='coerce')

# Convert amount columns to numeric (already numeric, but ensure)
orders['amount'] = pd.to_numeric(orders['amount'], errors='coerce')
payments['amount'] = pd.to_numeric(payments['amount'], errors='coerce')

# Convert customer_id to numeric
customers['customer_id'] = pd.to_numeric(customers['customer_id'], errors='coerce')
orders['customer_id'] = pd.to_numeric(orders['customer_id'], errors='coerce')

print(f"\nOriginal record counts:")
print(f"  Customers: {len(customers)}")
print(f"  Orders: {len(orders)}")
print(f"  Payments: {len(payments)}")

# Keep only records where we have valid IDs
customers_clean = customers[customers['customer_id'].notna()].copy()
orders_clean = orders[(orders['order_id'].notna()) & (orders['customer_id'].notna())].copy()
payments_clean = payments[(payments['payment_id'].notna()) & (payments['order_id'].notna())].copy()

print(f"\nCleaned record counts (valid IDs only):")
print(f"  Customers: {len(customers_clean)}")
print(f"  Orders: {len(orders_clean)}")
print(f"  Payments: {len(payments_clean)}")

# Save all customers (for dashboard to show complete list)
customers_clean.to_csv(os.path.join(data_dir, 'all_customers.csv'), index=False)

# Merge orders with customers
print("\nMerging orders with customers...")
orders_cust = orders_clean.merge(customers_clean, on='customer_id', how='left', suffixes=('', '_cust'))

# Merge payments with orders (and thus customers)
print("Merging payments with orders...")
payments_orders = payments_clean.merge(orders_cust, on='order_id', how='left', suffixes=('', '_order'))

# Remove rows where merge failed (no matching customer/order)
payments_orders = payments_orders[payments_orders['customer_id'].notna()].copy()

print(f"\nFinal merged dataset: {len(payments_orders)} payment records with complete customer/order info")
print(f"Unique customers with payments: {payments_orders['customer_id'].nunique()}")
print(f"Unique orders: {payments_orders['order_id'].nunique()}")

# Save merged data for next steps
payments_orders.to_csv(os.path.join(data_dir, 'merged_payments_orders.csv'), index=False)

# Create a customer summary showing who has payment data
customer_payment_summary = customers_clean[['customer_id', 'full_name', 'email', 'reg_date', 'dq_score']].copy()
customer_payment_summary['has_payment_data'] = customer_payment_summary['customer_id'].isin(payments_orders['customer_id'].unique())
customer_payment_summary['num_payments'] = customer_payment_summary['customer_id'].map(
    payments_orders.groupby('customer_id').size()
).fillna(0).astype(int)
customer_payment_summary.to_csv(os.path.join(data_dir, 'customer_summary.csv'), index=False)

print(f'\n✓ Data loaded, preprocessed, and merged successfully!')
print(f'✓ Merged file saved to {data_dir}/merged_payments_orders.csv')
print(f'✓ All customers saved to {data_dir}/all_customers.csv')
print(f'✓ Customer summary saved to {data_dir}/customer_summary.csv')
print(f'\nCustomers with payment data: {customer_payment_summary["has_payment_data"].sum()}/{len(customer_payment_summary)}')
print(f'\nReady for feature engineering!')
