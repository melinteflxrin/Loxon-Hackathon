import pandas as pd
import numpy as np
import os

# Get the project root (one level up from src)
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))

# Load merged data
merged_data = pd.read_csv(os.path.join(data_dir, 'merged_payments_orders.csv'))

# Convert date columns to datetime (in case they're loaded as strings)
merged_data['order_date'] = pd.to_datetime(merged_data['order_date'])
merged_data['payment_date'] = pd.to_datetime(merged_data['payment_date'])
merged_data['reg_date'] = pd.to_datetime(merged_data['reg_date'])

# Calculate payment delay (in days)
merged_data['payment_delay_days'] = (merged_data['payment_date'] - merged_data['order_date']).dt.days

# Feature engineering per customer
print("Engineering features per customer...")

customer_features = merged_data.groupby('customer_id').agg({
    # Count features
    'order_id': 'nunique',  # Number of unique orders
    'payment_id': 'count',   # Number of payments
    
    # Amount features
    'amount': ['sum', 'mean', 'median', 'std'],  # Payment amount statistics
    'amount_order': ['sum', 'mean', 'median'],   # Order amount statistics
    
    # Delay features
    'payment_delay_days': ['mean', 'median', 'min', 'max', 'std'],
    
    # Temporal features
    'payment_date': ['min', 'max'],  # First and last payment dates
    'reg_date': 'first'  # Registration date
}).reset_index()

# Flatten column names
customer_features.columns = ['_'.join(col).strip('_') if col[1] else col[0] 
                              for col in customer_features.columns.values]

# Calculate recency (days since last payment)
current_date = merged_data['payment_date'].max()
customer_features['recency_days'] = (current_date - customer_features['payment_date_max']).dt.days

# Calculate customer lifetime (days since registration)
customer_features['customer_lifetime_days'] = (current_date - customer_features['reg_date_first']).dt.days

# Calculate payment frequency (payments per day of customer lifetime)
customer_features['payment_frequency'] = (
    customer_features['payment_id_count'] / 
    customer_features['customer_lifetime_days'].replace(0, 1)  # Avoid division by zero
)

# Get most common payment method per customer
most_common_method = merged_data.groupby('customer_id')['method'].agg(
    lambda x: x.value_counts().index[0] if len(x) > 0 else 'unknown'
).reset_index()
most_common_method.columns = ['customer_id', 'preferred_method']

customer_features = customer_features.merge(most_common_method, on='customer_id', how='left')

# Fill NaN values (e.g., std might be NaN for customers with only 1 payment)
customer_features.fillna(0, inplace=True)

# Save features
customer_features.to_csv(os.path.join(data_dir, 'customer_features.csv'), index=False)

print(f"Feature engineering complete! {len(customer_features)} customers with {len(customer_features.columns)} features.")
print(f"Features saved to {data_dir}/customer_features.csv")
print("\nFeature columns:")
print(customer_features.columns.tolist())
print("\nFirst few rows:")
print(customer_features.head())
