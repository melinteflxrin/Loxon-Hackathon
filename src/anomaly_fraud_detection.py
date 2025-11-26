import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest
from sklearn.covariance import EllipticEnvelope
from sklearn.svm import OneClassSVM
import warnings
warnings.filterwarnings('ignore')

# Get the project root (one level up from src)
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))
output_dir = os.path.abspath(os.path.join(script_dir, '..', 'output'))
os.makedirs(output_dir, exist_ok=True)

print("="*80)
print("ANOMALY & FRAUD DETECTION IN CUSTOMER PAYMENT BEHAVIOR")
print("="*80)

# Load customer features
print("\nLoading customer features...")
customer_features = pd.read_csv(os.path.join(data_dir, 'customer_features.csv'))

# Load merged payment data for transaction-level analysis
print("Loading payment transaction data...")
merged_data = pd.read_csv(os.path.join(data_dir, 'merged_payments_orders.csv'))
merged_data['order_date'] = pd.to_datetime(merged_data['order_date'])
merged_data['payment_date'] = pd.to_datetime(merged_data['payment_date'])
merged_data['payment_delay_days'] = (merged_data['payment_date'] - merged_data['order_date']).dt.days

print(f"Total customers: {len(customer_features)}")
print(f"Total transactions: {len(merged_data)}")

# ============================================================================
# PART 1: CUSTOMER-LEVEL ANOMALY DETECTION
# ============================================================================
print("\n" + "="*80)
print("PART 1: CUSTOMER-LEVEL ANOMALY DETECTION")
print("="*80)

# Select features for anomaly detection
feature_columns = [
    'order_id_nunique', 'payment_id_count', 'amount_sum', 'amount_mean',
    'payment_delay_days_mean', 'payment_delay_days_max', 
    'recency_days', 'payment_frequency'
]

X_customer = customer_features[feature_columns].copy()
X_customer = X_customer.replace([np.inf, -np.inf], np.nan).fillna(0)

# Standardize features
scaler_customer = StandardScaler()
X_customer_scaled = scaler_customer.fit_transform(X_customer)

print(f"\nUsing {len(feature_columns)} features for customer anomaly detection")

# Method 1: Isolation Forest (best for high-dimensional data)
print("\n--- Method 1: Isolation Forest ---")
iso_forest = IsolationForest(
    contamination=0.1,  # Assume 10% are anomalies
    random_state=42,
    n_estimators=100
)
customer_features['anomaly_iso_forest'] = iso_forest.fit_predict(X_customer_scaled)
customer_features['anomaly_score_iso_forest'] = iso_forest.score_samples(X_customer_scaled)

# -1 means anomaly, 1 means normal
anomalies_if = customer_features[customer_features['anomaly_iso_forest'] == -1]
print(f"Isolation Forest detected {len(anomalies_if)} anomalous customers ({len(anomalies_if)/len(customer_features)*100:.1f}%)")

# Method 2: One-Class SVM
print("\n--- Method 2: One-Class SVM ---")
oc_svm = OneClassSVM(nu=0.1, kernel='rbf', gamma='auto')
customer_features['anomaly_svm'] = oc_svm.fit_predict(X_customer_scaled)
customer_features['anomaly_score_svm'] = oc_svm.score_samples(X_customer_scaled)

anomalies_svm = customer_features[customer_features['anomaly_svm'] == -1]
print(f"One-Class SVM detected {len(anomalies_svm)} anomalous customers ({len(anomalies_svm)/len(customer_features)*100:.1f}%)")

# Method 3: Elliptic Envelope (assumes Gaussian distribution)
print("\n--- Method 3: Elliptic Envelope ---")
elliptic = EllipticEnvelope(contamination=0.1, random_state=42)
customer_features['anomaly_elliptic'] = elliptic.fit_predict(X_customer_scaled)

anomalies_ee = customer_features[customer_features['anomaly_elliptic'] == -1]
print(f"Elliptic Envelope detected {len(anomalies_ee)} anomalous customers ({len(anomalies_ee)/len(customer_features)*100:.1f}%)")

# Consensus: Mark as anomaly if detected by at least 2 methods
customer_features['anomaly_consensus'] = (
    (customer_features['anomaly_iso_forest'] == -1).astype(int) +
    (customer_features['anomaly_svm'] == -1).astype(int) +
    (customer_features['anomaly_elliptic'] == -1).astype(int)
)
customer_features['is_anomaly'] = customer_features['anomaly_consensus'] >= 2

consensus_anomalies = customer_features[customer_features['is_anomaly']]
print(f"\n[OK] Consensus: {len(consensus_anomalies)} customers flagged as anomalies ({len(consensus_anomalies)/len(customer_features)*100:.1f}%)")

# ============================================================================
# PART 2: TRANSACTION-LEVEL FRAUD DETECTION
# ============================================================================
print("\n" + "="*80)
print("PART 2: TRANSACTION-LEVEL FRAUD DETECTION")
print("="*80)

# Create transaction-level features for fraud detection
print("\nEngineering fraud detection features...")

# Feature 1: Unusual payment amounts (z-score)
merged_data['amount_zscore'] = np.abs((merged_data['amount'] - merged_data['amount'].mean()) / merged_data['amount'].std())

# Feature 2: Extreme payment delays
merged_data['delay_zscore'] = np.abs((merged_data['payment_delay_days'] - merged_data['payment_delay_days'].mean()) / 
                                      merged_data['payment_delay_days'].std())

# Feature 3: Weekend/holiday transactions (higher fraud risk)
merged_data['is_weekend'] = merged_data['payment_date'].dt.dayofweek.isin([5, 6]).astype(int)

# Feature 4: Unusual time gaps between orders and payments
merged_data['unusual_delay'] = (np.abs(merged_data['payment_delay_days']) > 365).astype(int)

# Transaction risk scoring
transaction_features = ['amount_zscore', 'delay_zscore', 'is_weekend', 'unusual_delay']
X_transaction = merged_data[transaction_features].copy()
X_transaction = X_transaction.fillna(0)

# Standardize
scaler_transaction = StandardScaler()
X_transaction_scaled = scaler_transaction.fit_transform(X_transaction)

# Apply Isolation Forest for transaction-level fraud detection
print("\nApplying Isolation Forest for transaction fraud detection...")
iso_forest_txn = IsolationForest(
    contamination=0.05,  # Assume 5% fraudulent transactions
    random_state=42,
    n_estimators=100
)
merged_data['fraud_prediction'] = iso_forest_txn.fit_predict(X_transaction_scaled)
merged_data['fraud_score'] = iso_forest_txn.score_samples(X_transaction_scaled)

# Calculate fraud risk score (0-100, higher = more suspicious)
merged_data['fraud_risk_score'] = ((1 - (merged_data['fraud_score'] - merged_data['fraud_score'].min()) / 
                                    (merged_data['fraud_score'].max() - merged_data['fraud_score'].min())) * 100)

fraudulent_txns = merged_data[merged_data['fraud_prediction'] == -1]
print(f"\n[OK] Detected {len(fraudulent_txns)} potentially fraudulent transactions ({len(fraudulent_txns)/len(merged_data)*100:.1f}%)")

# ============================================================================
# ANALYSIS & PROFILING
# ============================================================================
print("\n" + "="*80)
print("ANOMALOUS CUSTOMER PROFILE")
print("="*80)

if len(consensus_anomalies) > 0:
    print(f"\nTop anomalous customers by Isolation Forest score:")
    top_anomalies = customer_features.nsmallest(5, 'anomaly_score_iso_forest')[
        ['customer_id', 'amount_sum', 'payment_delay_days_mean', 'payment_id_count', 'anomaly_score_iso_forest']
    ]
    print(top_anomalies.to_string(index=False))
    
    print(f"\nCharacteristics of anomalous customers:")
    print(f"  - Avg payment delay: {consensus_anomalies['payment_delay_days_mean'].mean():.1f} days")
    print(f"  - Avg total amount: {consensus_anomalies['amount_sum'].mean():.2f} HUF")
    print(f"  - Avg payments: {consensus_anomalies['payment_id_count'].mean():.2f}")
    print(f"  - Avg recency: {consensus_anomalies['recency_days'].mean():.1f} days")
    
    print(f"\nCharacteristics of normal customers:")
    normal_customers = customer_features[~customer_features['is_anomaly']]
    print(f"  - Avg payment delay: {normal_customers['payment_delay_days_mean'].mean():.1f} days")
    print(f"  - Avg total amount: {normal_customers['amount_sum'].mean():.2f} HUF")
    print(f"  - Avg payments: {normal_customers['payment_id_count'].mean():.2f}")
    print(f"  - Avg recency: {normal_customers['recency_days'].mean():.1f} days")

print("\n" + "="*80)
print("FRAUDULENT TRANSACTION PROFILE")
print("="*80)

if len(fraudulent_txns) > 0:
    print(f"\nTop 5 most suspicious transactions:")
    top_fraud = merged_data.nlargest(5, 'fraud_risk_score')[
        ['payment_id', 'customer_id', 'amount', 'payment_delay_days', 'fraud_risk_score']
    ]
    print(top_fraud.to_string(index=False))
    
    print(f"\nCharacteristics of fraudulent transactions:")
    print(f"  - Avg amount: {fraudulent_txns['amount'].mean():.2f} HUF")
    print(f"  - Avg delay: {fraudulent_txns['payment_delay_days'].mean():.1f} days")
    print(f"  - Weekend transactions: {fraudulent_txns['is_weekend'].sum()} ({fraudulent_txns['is_weekend'].mean()*100:.1f}%)")
    
    print(f"\nCharacteristics of normal transactions:")
    normal_txns = merged_data[merged_data['fraud_prediction'] == 1]
    print(f"  - Avg amount: {normal_txns['amount'].mean():.2f} HUF")
    print(f"  - Avg delay: {normal_txns['payment_delay_days'].mean():.1f} days")
    print(f"  - Weekend transactions: {normal_txns['is_weekend'].sum()} ({normal_txns['is_weekend'].mean()*100:.1f}%)")

# ============================================================================
# VISUALIZATIONS
# ============================================================================
print("\n" + "="*80)
print("GENERATING VISUALIZATIONS")
print("="*80)

# Visualization 1: Customer anomaly scores distribution
fig, axes = plt.subplots(2, 2, figsize=(16, 12))

# Isolation Forest scores
axes[0, 0].hist(customer_features['anomaly_score_iso_forest'], bins=30, edgecolor='black', alpha=0.7)
axes[0, 0].axvline(customer_features[customer_features['is_anomaly']]['anomaly_score_iso_forest'].max(), 
                   color='red', linestyle='--', label='Anomaly Threshold')
axes[0, 0].set_title('Isolation Forest Anomaly Scores', fontsize=12, fontweight='bold')
axes[0, 0].set_xlabel('Anomaly Score')
axes[0, 0].set_ylabel('Frequency')
axes[0, 0].legend()

# One-Class SVM scores
axes[0, 1].hist(customer_features['anomaly_score_svm'], bins=30, edgecolor='black', alpha=0.7, color='orange')
axes[0, 1].set_title('One-Class SVM Anomaly Scores', fontsize=12, fontweight='bold')
axes[0, 1].set_xlabel('Anomaly Score')
axes[0, 1].set_ylabel('Frequency')

# Anomaly consensus
consensus_counts = customer_features['anomaly_consensus'].value_counts().sort_index()
axes[1, 0].bar(consensus_counts.index, consensus_counts.values, edgecolor='black', alpha=0.7, color='green')
axes[1, 0].set_title('Anomaly Detection Consensus', fontsize=12, fontweight='bold')
axes[1, 0].set_xlabel('Number of Methods Flagging as Anomaly')
axes[1, 0].set_ylabel('Number of Customers')
axes[1, 0].set_xticks([0, 1, 2, 3])

# Fraud risk score distribution
axes[1, 1].hist(merged_data['fraud_risk_score'], bins=30, edgecolor='black', alpha=0.7, color='red')
axes[1, 1].axvline(70, color='darkred', linestyle='--', linewidth=2, label='High Risk Threshold (70)')
axes[1, 1].set_title('Transaction Fraud Risk Score Distribution', fontsize=12, fontweight='bold')
axes[1, 1].set_xlabel('Fraud Risk Score (0-100)')
axes[1, 1].set_ylabel('Number of Transactions')
axes[1, 1].legend()

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'anomaly_fraud_analysis.png'), dpi=300, bbox_inches='tight')
print(f"[OK] Saved anomaly analysis visualization to {output_dir}/anomaly_fraud_analysis.png")

# Visualization 2: Feature comparison (anomalous vs normal)
fig, axes = plt.subplots(2, 2, figsize=(16, 10))

comparison_features = ['amount_sum', 'payment_delay_days_mean', 'payment_id_count', 'recency_days']
feature_labels = ['Total Payment Amount (HUF)', 'Avg Payment Delay (days)', 'Number of Payments', 'Recency (days)']

for idx, (feature, label) in enumerate(zip(comparison_features, feature_labels)):
    row, col = idx // 2, idx % 2
    
    data_to_plot = [
        customer_features[~customer_features['is_anomaly']][feature],
        customer_features[customer_features['is_anomaly']][feature]
    ]
    
    bp = axes[row, col].boxplot(data_to_plot, labels=['Normal', 'Anomaly'], patch_artist=True)
    bp['boxes'][0].set_facecolor('lightblue')
    bp['boxes'][1].set_facecolor('lightcoral')
    axes[row, col].set_title(label, fontsize=12, fontweight='bold')
    axes[row, col].set_ylabel('Value')
    axes[row, col].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'anomaly_feature_comparison.png'), dpi=300, bbox_inches='tight')
print(f"[OK] Saved feature comparison visualization to {output_dir}/anomaly_feature_comparison.png")

# ============================================================================
# SAVE RESULTS
# ============================================================================
print("\n" + "="*80)
print("SAVING RESULTS")
print("="*80)

# Save customer-level results
customer_features.to_csv(os.path.join(data_dir, 'customer_anomaly_detection.csv'), index=False)
print(f"[OK] Customer anomaly detection results saved to {data_dir}/customer_anomaly_detection.csv")

# Save transaction-level results
merged_data.to_csv(os.path.join(data_dir, 'transaction_fraud_detection.csv'), index=False)
print(f"[OK] Transaction fraud detection results saved to {data_dir}/transaction_fraud_detection.csv")

# Save high-risk report
high_risk_customers = customer_features[customer_features['is_anomaly']][
    ['customer_id', 'amount_sum', 'payment_delay_days_mean', 'payment_id_count', 
     'recency_days', 'anomaly_score_iso_forest', 'anomaly_consensus']
].sort_values('anomaly_score_iso_forest')

high_risk_customers.to_csv(os.path.join(output_dir, 'high_risk_customers.csv'), index=False)
print(f"[OK] High-risk customer report saved to {output_dir}/high_risk_customers.csv")

high_risk_txns = merged_data.nlargest(50, 'fraud_risk_score')[
    ['payment_id', 'customer_id', 'order_id', 'amount', 'payment_delay_days', 
     'fraud_risk_score', 'method']
]

high_risk_txns.to_csv(os.path.join(output_dir, 'high_risk_transactions.csv'), index=False)
print(f"[OK] High-risk transaction report saved to {output_dir}/high_risk_transactions.csv")

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "="*80)
print("ANOMALY & FRAUD DETECTION COMPLETE")
print("="*80)
print(f"\nSummary:")
print(f"  - Total customers analyzed: {len(customer_features)}")
print(f"  - Anomalous customers detected: {len(consensus_anomalies)} ({len(consensus_anomalies)/len(customer_features)*100:.1f}%)")
print(f"  - Total transactions analyzed: {len(merged_data)}")
print(f"  - Fraudulent transactions detected: {len(fraudulent_txns)} ({len(fraudulent_txns)/len(merged_data)*100:.1f}%)")
print(f"  - High-risk transactions (score > 70): {len(merged_data[merged_data['fraud_risk_score'] > 70])}")

print(f"\nOutput files generated:")
print(f"  - customer_anomaly_detection.csv")
print(f"  - transaction_fraud_detection.csv")
print(f"  - high_risk_customers.csv")
print(f"  - high_risk_transactions.csv")
print(f"  - anomaly_fraud_analysis.png")
print(f"  - anomaly_feature_comparison.png")

print("\n" + "="*80)
