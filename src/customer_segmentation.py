import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
import warnings
warnings.filterwarnings('ignore')

# Get the project root (one level up from src)
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))
output_dir = os.path.abspath(os.path.join(script_dir, '..', 'output'))
os.makedirs(output_dir, exist_ok=True)

# Load customer features
print("Loading customer features...")
customer_features = pd.read_csv(os.path.join(data_dir, 'customer_features.csv'))

# Select numerical features for clustering (exclude dates and customer_id)
date_columns = ['payment_date_min', 'payment_date_max', 'reg_date_first']
feature_columns = [col for col in customer_features.columns 
                   if col not in ['customer_id'] + date_columns and col != 'preferred_method']

# Prepare data for clustering
X = customer_features[feature_columns].copy()

# Handle any remaining NaN or infinite values
X = X.replace([np.inf, -np.inf], np.nan)
X = X.fillna(0)

print(f"\nUsing {len(feature_columns)} features for clustering:")
print(feature_columns)

# Standardize features (important for clustering)
print("\nStandardizing features...")
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Find optimal number of clusters using elbow method and silhouette score
print("\nFinding optimal number of clusters...")
inertias = []
silhouette_scores = []
K_range = range(2, 11)

for k in K_range:
    kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
    kmeans.fit(X_scaled)
    inertias.append(kmeans.inertia_)
    silhouette_scores.append(silhouette_score(X_scaled, kmeans.labels_))

# Plot elbow curve and silhouette scores
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

ax1.plot(K_range, inertias, 'bo-')
ax1.set_xlabel('Number of Clusters (k)')
ax1.set_ylabel('Inertia')
ax1.set_title('Elbow Method for Optimal k')
ax1.grid(True)

ax2.plot(K_range, silhouette_scores, 'ro-')
ax2.set_xlabel('Number of Clusters (k)')
ax2.set_ylabel('Silhouette Score')
ax2.set_title('Silhouette Score for Different k')
ax2.grid(True)

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'optimal_clusters.png'), dpi=300, bbox_inches='tight')
print(f"Saved cluster optimization plot to {output_dir}/optimal_clusters.png")

# Choose optimal k (you can adjust this based on the plots)
optimal_k = 4  # Default choice, can be adjusted
print(f"\nUsing k={optimal_k} clusters for segmentation")

# Perform final clustering
print("Performing K-Means clustering...")
kmeans = KMeans(n_clusters=optimal_k, random_state=42, n_init=10)
customer_features['segment'] = kmeans.fit_predict(X_scaled)

# Perform PCA for visualization
print("Performing PCA for visualization...")
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_scaled)
customer_features['pca_1'] = X_pca[:, 0]
customer_features['pca_2'] = X_pca[:, 1]

print(f"PCA explained variance: {pca.explained_variance_ratio_.sum():.2%}")

# Visualize clusters in PCA space
plt.figure(figsize=(12, 8))
scatter = plt.scatter(customer_features['pca_1'], 
                     customer_features['pca_2'], 
                     c=customer_features['segment'], 
                     cmap='viridis', 
                     s=100, 
                     alpha=0.6,
                     edgecolors='black')
plt.xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.1%} variance)')
plt.ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.1%} variance)')
plt.title('Customer Segments (K-Means Clustering)')
plt.colorbar(scatter, label='Segment')
plt.grid(True, alpha=0.3)
plt.savefig(os.path.join(output_dir, 'customer_segments_pca.png'), dpi=300, bbox_inches='tight')
print(f"Saved PCA visualization to {output_dir}/customer_segments_pca.png")

# Profile each segment
print("\n" + "="*80)
print("SEGMENT PROFILING")
print("="*80)

segment_profiles = customer_features.groupby('segment')[feature_columns].mean()

for segment in range(optimal_k):
    print(f"\n{'='*80}")
    print(f"SEGMENT {segment} - {len(customer_features[customer_features['segment'] == segment])} customers")
    print(f"{'='*80}")
    
    segment_data = customer_features[customer_features['segment'] == segment]
    
    print(f"\nKey characteristics:")
    print(f"  - Avg orders per customer: {segment_data['order_id_nunique'].mean():.2f}")
    print(f"  - Avg payments per customer: {segment_data['payment_id_count'].mean():.2f}")
    print(f"  - Avg total payment amount: {segment_data['amount_sum'].mean():.2f} HUF")
    print(f"  - Avg payment delay: {segment_data['payment_delay_days_mean'].mean():.1f} days")
    print(f"  - Avg recency: {segment_data['recency_days'].mean():.1f} days")
    print(f"  - Avg payment frequency: {segment_data['payment_frequency'].mean():.6f}")
    print(f"  - Most common payment method: {segment_data['preferred_method'].mode()[0] if len(segment_data) > 0 else 'N/A'}")

# Create heatmap of segment characteristics
plt.figure(figsize=(14, 10))
segment_profiles_normalized = (segment_profiles - segment_profiles.min()) / (segment_profiles.max() - segment_profiles.min())
sns.heatmap(segment_profiles_normalized.T, annot=False, cmap='RdYlGn', 
            xticklabels=[f'Segment {i}' for i in range(optimal_k)],
            yticklabels=feature_columns, cbar_kws={'label': 'Normalized Value'})
plt.title('Customer Segment Profiles (Normalized Features)', fontsize=14, fontweight='bold')
plt.xlabel('Segment')
plt.ylabel('Feature')
plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'segment_heatmap.png'), dpi=300, bbox_inches='tight')
print(f"\nSaved segment heatmap to {output_dir}/segment_heatmap.png")

# Save segmented customer data
customer_features.to_csv(os.path.join(data_dir, 'customer_segments.csv'), index=False)
print(f"\nSegmented customer data saved to {data_dir}/customer_segments.csv")

# Create summary report
print("\n" + "="*80)
print("CLUSTERING SUMMARY")
print("="*80)
print(f"Total customers: {len(customer_features)}")
print(f"Number of segments: {optimal_k}")
print(f"Silhouette score: {silhouette_score(X_scaled, customer_features['segment']):.3f}")
print(f"\nSegment distribution:")
print(customer_features['segment'].value_counts().sort_index())
print("\n" + "="*80)
print("AI-based customer payment behaviour segmentation complete!")
print("="*80)
