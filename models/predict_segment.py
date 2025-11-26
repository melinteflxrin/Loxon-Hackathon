import pandas as pd
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
