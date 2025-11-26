import pandas as pd
import numpy as np
import os

# Get the project root (one level up from src)
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))

# Load data
customers = pd.read_csv(os.path.join(data_dir, 'mock_st_customers.csv'))
orders = pd.read_csv(os.path.join(data_dir, 'mock_st_orders.csv'))
payments = pd.read_csv(os.path.join(data_dir, 'mock_st_payments.csv'))

# Convert date columns to datetime
customers['reg_date'] = pd.to_datetime(customers['reg_date'])
orders['order_date'] = pd.to_datetime(orders['order_date'])
payments['payment_date'] = pd.to_datetime(payments['payment_date'])

# Convert amount columns to numeric
orders['amount'] = pd.to_numeric(orders['amount'])
payments['amount'] = pd.to_numeric(payments['amount'])

# Merge orders with customers
orders_cust = orders.merge(customers, on='customer_id', how='left')
# Merge payments with orders (and thus customers)
payments_orders = payments.merge(orders_cust, on='order_id', how='left', suffixes=('', '_order'))

# Save merged data for next steps
payments_orders.to_csv(os.path.join(data_dir, 'merged_payments_orders.csv'), index=False)

print(f'Data loaded, preprocessed, and merged. Ready for feature engineering! Merged file saved to {data_dir}')
