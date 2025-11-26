import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
from sklearn.metrics import roc_curve, auc
import joblib
import warnings
warnings.filterwarnings('ignore')

# Get the project root
script_dir = os.path.dirname(os.path.abspath(__file__))
data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))
output_dir = os.path.abspath(os.path.join(script_dir, '..', 'output'))
models_dir = os.path.abspath(os.path.join(script_dir, '..', 'models'))
os.makedirs(output_dir, exist_ok=True)
os.makedirs(models_dir, exist_ok=True)

print("="*80)
print("PREDICTIVE MODELING FOR CUSTOMER SEGMENT CLASSIFICATION")
print("="*80)

# Load customer features with segments
print("\nLoading customer data with segments...")
customer_segments = pd.read_csv(os.path.join(data_dir, 'customer_segments.csv'))

print(f"Total customers: {len(customer_segments)}")
print(f"Segment distribution:\n{customer_segments['segment'].value_counts().sort_index()}")

# Select features for prediction (exclude IDs, dates, PCA components, and target)
exclude_cols = ['customer_id', 'segment', 'payment_date_min', 'payment_date_max', 
                'reg_date_first', 'pca_1', 'pca_2', 'preferred_method']

feature_columns = [col for col in customer_segments.columns if col not in exclude_cols]

print(f"\nUsing {len(feature_columns)} features for prediction:")
print(feature_columns)

# Prepare features (X) and target (y)
X = customer_segments[feature_columns].copy()
y = customer_segments['segment'].copy()

# Handle any missing or infinite values
X = X.replace([np.inf, -np.inf], np.nan).fillna(0)

# Split data into train and test sets
print("\nSplitting data into train (80%) and test (20%) sets...")
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

print(f"Training samples: {len(X_train)}")
print(f"Testing samples: {len(X_test)}")

# Standardize features
print("\nStandardizing features...")
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# ============================================================================
# MODEL TRAINING & COMPARISON
# ============================================================================
print("\n" + "="*80)
print("TRAINING AND COMPARING MULTIPLE MODELS")
print("="*80)

models = {
    'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42, max_depth=10),
    'Gradient Boosting': GradientBoostingClassifier(n_estimators=100, random_state=42, max_depth=5),
    'Logistic Regression': LogisticRegression(random_state=42, max_iter=1000, multi_class='multinomial')
}

results = {}

for model_name, model in models.items():
    print(f"\n--- Training {model_name} ---")
    
    # Train model
    model.fit(X_train_scaled, y_train)
    
    # Predictions
    y_pred_train = model.predict(X_train_scaled)
    y_pred_test = model.predict(X_test_scaled)
    
    # Evaluate
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred_test)
    test_f1 = f1_score(y_test, y_pred_test, average='weighted')
    
    # Cross-validation
    cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=5, scoring='accuracy')
    
    results[model_name] = {
        'model': model,
        'train_accuracy': train_accuracy,
        'test_accuracy': test_accuracy,
        'test_f1': test_f1,
        'cv_mean': cv_scores.mean(),
        'cv_std': cv_scores.std(),
        'y_pred': y_pred_test
    }
    
    print(f"  Training Accuracy: {train_accuracy:.3f}")
    print(f"  Test Accuracy: {test_accuracy:.3f}")
    print(f"  Test F1-Score: {test_f1:.3f}")
    print(f"  Cross-validation: {cv_scores.mean():.3f} (+/- {cv_scores.std():.3f})")

# Select best model based on test accuracy
best_model_name = max(results, key=lambda x: results[x]['test_accuracy'])
best_model = results[best_model_name]['model']

print("\n" + "="*80)
print(f"BEST MODEL: {best_model_name}")
print(f"Test Accuracy: {results[best_model_name]['test_accuracy']:.3f}")
print(f"Test F1-Score: {results[best_model_name]['test_f1']:.3f}")
print("="*80)

# ============================================================================
# DETAILED EVALUATION OF BEST MODEL
# ============================================================================
print("\n" + "="*80)
print("DETAILED EVALUATION")
print("="*80)

y_pred_best = results[best_model_name]['y_pred']

# Classification report
print("\nClassification Report:")
print(classification_report(y_test, y_pred_best, 
                          target_names=[f"Segment {i}" for i in sorted(y.unique())]))

# Confusion matrix
print("\nConfusion Matrix:")
cm = confusion_matrix(y_test, y_pred_best)
print(cm)

# ============================================================================
# FEATURE IMPORTANCE ANALYSIS
# ============================================================================
print("\n" + "="*80)
print("FEATURE IMPORTANCE ANALYSIS")
print("="*80)

if hasattr(best_model, 'feature_importances_'):
    # For tree-based models
    feature_importance = pd.DataFrame({
        'feature': feature_columns,
        'importance': best_model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    print("\nTop 10 Most Important Features:")
    print(feature_importance.head(10).to_string(index=False))
    
    # Save feature importance
    feature_importance.to_csv(os.path.join(output_dir, 'feature_importance.csv'), index=False)
    
elif hasattr(best_model, 'coef_'):
    # For linear models
    # Average absolute coefficients across all classes
    feature_importance = pd.DataFrame({
        'feature': feature_columns,
        'importance': np.abs(best_model.coef_).mean(axis=0)
    }).sort_values('importance', ascending=False)
    
    print("\nTop 10 Most Important Features:")
    print(feature_importance.head(10).to_string(index=False))
    
    feature_importance.to_csv(os.path.join(output_dir, 'feature_importance.csv'), index=False)

# ============================================================================
# VISUALIZATIONS
# ============================================================================
print("\n" + "="*80)
print("GENERATING VISUALIZATIONS")
print("="*80)

# 1. Model comparison
fig, axes = plt.subplots(2, 2, figsize=(16, 12))

# Accuracy comparison
model_names = list(results.keys())
train_accs = [results[m]['train_accuracy'] for m in model_names]
test_accs = [results[m]['test_accuracy'] for m in model_names]

x_pos = np.arange(len(model_names))
width = 0.35

axes[0, 0].bar(x_pos - width/2, train_accs, width, label='Training', alpha=0.8)
axes[0, 0].bar(x_pos + width/2, test_accs, width, label='Testing', alpha=0.8)
axes[0, 0].set_xlabel('Model')
axes[0, 0].set_ylabel('Accuracy')
axes[0, 0].set_title('Model Accuracy Comparison', fontsize=12, fontweight='bold')
axes[0, 0].set_xticks(x_pos)
axes[0, 0].set_xticklabels(model_names, rotation=15, ha='right')
axes[0, 0].legend()
axes[0, 0].grid(True, alpha=0.3)

# Confusion matrix heatmap
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[0, 1],
            xticklabels=[f'S{i}' for i in sorted(y.unique())],
            yticklabels=[f'S{i}' for i in sorted(y.unique())])
axes[0, 1].set_title(f'Confusion Matrix - {best_model_name}', fontsize=12, fontweight='bold')
axes[0, 1].set_xlabel('Predicted Segment')
axes[0, 1].set_ylabel('True Segment')

# Feature importance (top 15)
if 'feature_importance' in locals():
    top_features = feature_importance.head(15)
    axes[1, 0].barh(range(len(top_features)), top_features['importance'])
    axes[1, 0].set_yticks(range(len(top_features)))
    axes[1, 0].set_yticklabels(top_features['feature'], fontsize=9)
    axes[1, 0].set_xlabel('Importance')
    axes[1, 0].set_title('Top 15 Feature Importance', fontsize=12, fontweight='bold')
    axes[1, 0].invert_yaxis()
    axes[1, 0].grid(True, alpha=0.3, axis='x')

# Cross-validation scores comparison
cv_means = [results[m]['cv_mean'] for m in model_names]
cv_stds = [results[m]['cv_std'] for m in model_names]

axes[1, 1].bar(x_pos, cv_means, yerr=cv_stds, capsize=5, alpha=0.8, color='green')
axes[1, 1].set_xlabel('Model')
axes[1, 1].set_ylabel('Cross-Validation Accuracy')
axes[1, 1].set_title('Cross-Validation Performance', fontsize=12, fontweight='bold')
axes[1, 1].set_xticks(x_pos)
axes[1, 1].set_xticklabels(model_names, rotation=15, ha='right')
axes[1, 1].grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig(os.path.join(output_dir, 'predictive_model_evaluation.png'), dpi=300, bbox_inches='tight')
print(f"[OK] Saved model evaluation visualization to {output_dir}/predictive_model_evaluation.png")

# ============================================================================
# SAVE MODEL AND ARTIFACTS
# ============================================================================
print("\n" + "="*80)
print("SAVING MODEL AND ARTIFACTS")
print("="*80)

# Save best model
model_path = os.path.join(models_dir, 'segment_classifier.pkl')
joblib.dump(best_model, model_path)
print(f"[OK] Saved best model ({best_model_name}) to {model_path}")

# Save scaler
scaler_path = os.path.join(models_dir, 'feature_scaler.pkl')
joblib.dump(scaler, scaler_path)
print(f"[OK] Saved feature scaler to {scaler_path}")

# Save feature names
feature_info = {
    'feature_columns': feature_columns,
    'model_name': best_model_name,
    'test_accuracy': results[best_model_name]['test_accuracy'],
    'test_f1': results[best_model_name]['test_f1']
}

import json
with open(os.path.join(models_dir, 'model_info.json'), 'w') as f:
    json.dump(feature_info, f, indent=4)
print(f"[OK] Saved model metadata to {models_dir}/model_info.json")

# Save predictions
predictions_df = pd.DataFrame({
    'customer_id': customer_segments.iloc[X_test.index]['customer_id'],
    'true_segment': y_test,
    'predicted_segment': y_pred_best,
    'correct': y_test == y_pred_best
})
predictions_df.to_csv(os.path.join(output_dir, 'test_predictions.csv'), index=False)
print(f"[OK] Saved test predictions to {output_dir}/test_predictions.csv")

# ============================================================================
# CREATE PREDICTION FUNCTION
# ============================================================================
print("\n" + "="*80)
print("CREATING PREDICTION UTILITY")
print("="*80)

# Create a simple prediction script
prediction_script = '''import pandas as pd
import numpy as np
import joblib
import os

# Load model and scaler
models_dir = os.path.join(os.path.dirname(__file__), '..', 'models')
model = joblib.load(os.path.join(models_dir, 'segment_classifier.pkl'))
scaler = joblib.load(os.path.join(models_dir, 'feature_scaler.pkl'))

# Load feature info
import json
with open(os.path.join(models_dir, 'model_info.json'), 'r') as f:
    model_info = json.load(f)

feature_columns = model_info['feature_columns']

def predict_customer_segment(customer_features_dict):
    """
    Predict the segment for a new customer.
    
    Parameters:
    -----------
    customer_features_dict : dict
        Dictionary containing customer features with keys matching feature_columns
        
    Returns:
    --------
    dict : Prediction results including segment, probability, and confidence
    """
    # Create dataframe from input
    customer_df = pd.DataFrame([customer_features_dict])
    
    # Ensure all required features are present
    for feature in feature_columns:
        if feature not in customer_df.columns:
            customer_df[feature] = 0
    
    # Select and order features
    X = customer_df[feature_columns].copy()
    X = X.replace([np.inf, -np.inf], np.nan).fillna(0)
    
    # Scale features
    X_scaled = scaler.transform(X)
    
    # Predict
    predicted_segment = model.predict(X_scaled)[0]
    
    # Get probability if available
    if hasattr(model, 'predict_proba'):
        probabilities = model.predict_proba(X_scaled)[0]
        confidence = probabilities.max()
        all_probs = {f'segment_{i}': prob for i, prob in enumerate(probabilities)}
    else:
        confidence = 1.0
        all_probs = {}
    
    return {
        'predicted_segment': int(predicted_segment),
        'confidence': float(confidence),
        'probabilities': all_probs,
        'model_name': model_info['model_name'],
        'model_accuracy': model_info['test_accuracy']
    }

# Example usage
if __name__ == "__main__":
    # Example: Predict segment for a new customer
    example_customer = {
        'order_id_nunique': 3,
        'payment_id_count': 5,
        'amount_sum': 5000,
        'amount_mean': 1000,
        'amount_median': 950,
        'amount_std': 150,
        'amount_order_sum': 5100,
        'amount_order_mean': 1020,
        'amount_order_median': 1000,
        'payment_delay_days_mean': -30,
        'payment_delay_days_median': -25,
        'payment_delay_days_min': -60,
        'payment_delay_days_max': 10,
        'payment_delay_days_std': 25,
        'recency_days': 45,
        'customer_lifetime_days': 180,
        'payment_frequency': 0.028
    }
    
    result = predict_customer_segment(example_customer)
    print("Prediction Result:")
    print(f"  Segment: {result['predicted_segment']}")
    print(f"  Confidence: {result['confidence']:.2%}")
    print(f"  Model: {result['model_name']}")
    print(f"  Model Accuracy: {result['model_accuracy']:.2%}")
    if result['probabilities']:
        print("  Probabilities:")
        for seg, prob in result['probabilities'].items():
            print(f"    {seg}: {prob:.2%}")
'''

with open(os.path.join(models_dir, 'predict_segment.py'), 'w') as f:
    f.write(prediction_script)

print(f"[OK] Created prediction utility at {models_dir}/predict_segment.py")

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "="*80)
print("PREDICTIVE MODELING COMPLETE")
print("="*80)

print(f"\nSummary:")
print(f"  - Best Model: {best_model_name}")
print(f"  - Test Accuracy: {results[best_model_name]['test_accuracy']:.2%}")
print(f"  - Test F1-Score: {results[best_model_name]['test_f1']:.2%}")
print(f"  - Cross-Validation: {results[best_model_name]['cv_mean']:.2%} (+/- {results[best_model_name]['cv_std']:.2%})")
print(f"  - Training samples: {len(X_train)}")
print(f"  - Test samples: {len(X_test)}")

print(f"\nFiles generated:")
print(f"  - {models_dir}/segment_classifier.pkl (trained model)")
print(f"  - {models_dir}/feature_scaler.pkl (feature scaler)")
print(f"  - {models_dir}/model_info.json (model metadata)")
print(f"  - {models_dir}/predict_segment.py (prediction utility)")
print(f"  - {output_dir}/feature_importance.csv")
print(f"  - {output_dir}/test_predictions.csv")
print(f"  - {output_dir}/predictive_model_evaluation.png")

print("\n" + "="*80)
print("You can now use the model to predict segments for new customers!")
print("Run: python models/predict_segment.py")
print("="*80)
