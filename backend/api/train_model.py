"""
ML Model Training Script for Health Tracker System
Trains Random Forest classifier for risk prediction using:
- 12-question symptom scores (0-3 scale each)
- Baseline clinical data integration
- Deviation-from-baseline features

Output: risk_model_v2.pkl will be created in ml_models/ directory
"""
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import os
import random

# Set seed for reproducibility
random.seed(42)
np.random.seed(42)

def generate_training_data():
    """
    Generate synthetic training data:
    - 500 total samples
    - 12 questions each (0-3 scale)
    - Baseline clinical data
    - Risk labels: 0=GREEN, 1=YELLOW, 2=ORANGE, 3=RED
    
    Feature array structure:
    [q1-q12 (12 features), systolic_deviation, diastolic_deviation, glucose_deviation, 
     medication_adherence, condition_code, age_normalized]
    = 19 features total
    """
    samples = []
    labels = []
    
    conditions = ['Hypertension', 'Diabetes', 'Cardiovascular']
    condition_codes = {'Hypertension': 0, 'Diabetes': 1, 'Cardiovascular': 2}
    
    # Generate 500 synthetic samples
    for _ in range(500):
        condition = random.choice(conditions)
        condition_code = condition_codes[condition]
        
        # Random baseline values
        baseline_systolic = random.randint(90, 180)
        baseline_diastolic = random.randint(60, 110)
        baseline_glucose = random.randint(100, 180)
        age = random.randint(25, 85)
        
        # Generate symptom scores (0-3) - biased toward risk category
        risk_category = random.choices([0, 1, 2, 3], weights=[30, 30, 20, 20])[0]
        
        if risk_category == 0:  # GREEN - low symptoms
            symptom_scores = [random.randint(0, 1) for _ in range(12)]
            symptom_scores[-1] = random.choice([2, 3])  # Medication taken
            # BP and glucose close to baseline
            current_systolic = baseline_systolic + random.randint(-10, 10)
            current_diastolic = baseline_diastolic + random.randint(-8, 8)
            current_glucose = baseline_glucose + random.randint(-20, 20)
            medication_adherence = 1  # Took medication
            
        elif risk_category == 1:  # YELLOW - mild symptoms
            symptom_scores = [random.randint(0, 2) for _ in range(11)]
            symptom_scores.append(random.choice([1, 2, 3]))  # Medication status varied
            # BP and glucose slightly elevated
            current_systolic = baseline_systolic + random.randint(5, 30)
            current_diastolic = baseline_diastolic + random.randint(3, 20)
            current_glucose = baseline_glucose + random.randint(20, 60)
            medication_adherence = random.choice([0, 1])
            
        elif risk_category == 2:  # ORANGE - moderate symptoms
            symptom_scores = [random.randint(1, 3) for _ in range(12)]
            # Multiple high scores
            for i in range(random.randint(3, 5)):
                symptom_scores[random.randint(0, 11)] = 3
            # BP and glucose notably elevated
            current_systolic = baseline_systolic + random.randint(30, 60)
            current_diastolic = baseline_diastolic + random.randint(20, 40)
            current_glucose = baseline_glucose + random.randint(60, 120)
            medication_adherence = random.choice([0, 1])  # Inconsistent
            
        else:  # RED - severe symptoms
            symptom_scores = [random.randint(2, 3) for _ in range(12)]
            # Many critical scores
            for i in range(random.randint(6, 10)):
                symptom_scores[random.randint(0, 11)] = 3
            # BP and glucose highly elevated
            current_systolic = baseline_systolic + random.randint(60, 100)
            current_diastolic = baseline_diastolic + random.randint(40, 70)
            current_glucose = baseline_glucose + random.randint(120, 200)
            medication_adherence = 0  # Not adherent
        
        # Calculate deviations from baseline
        systolic_deviation = current_systolic - baseline_systolic
        diastolic_deviation = current_diastolic - baseline_diastolic
        glucose_deviation = current_glucose - baseline_glucose
        
        # Normalize age (25-85 → 0-1)
        age_normalized = (age - 25) / 60
        
        # Build feature vector
        features = (
            symptom_scores +  # q1-q12: 12 features
            [systolic_deviation, diastolic_deviation, glucose_deviation,  # 3 features
             medication_adherence, condition_code, age_normalized]  # 3 features
        )
        
        samples.append(features)
        labels.append(risk_category)
    
    return np.array(samples), np.array(labels)


def train_model():
    """Train and evaluate the Random Forest model"""
    
    print("=" * 70)
    print("🚀 Health Tracker ML Model Training - 12 Questions + Baseline Data")
    print("=" * 70)
    
    # Generate training data
    print("\n📊 Generating synthetic training data...")
    X, y = generate_training_data()
    print(f"   Generated {len(X)} samples with {X.shape[1]} features")
    
    # Display class distribution
    unique, counts = np.unique(y, return_counts=True)
    print("\n   Class distribution:")
    class_names = {0: 'GREEN', 1: 'YELLOW', 2: 'ORANGE', 3: 'RED'}
    for class_id, count in zip(unique, counts):
        pct = (count / len(y)) * 100
        print(f"      {class_names[class_id]}: {count} ({pct:.1f}%)")
    
    # Split data
    print("\n📈 Splitting data: 80% train, 20% test...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"   Training set: {len(X_train)} samples")
    print(f"   Test set: {len(X_test)} samples")
    
    # Train model
    print("\n🧠 Training Random Forest classifier...")
    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1
    )
    model.fit(X_train, y_train)
    print("   ✅ Training complete!")
    
    # Evaluate
    print("\n📊 Evaluating model performance...")
    y_pred = model.predict(X_test)
    y_pred_train = model.predict(X_train)
    
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred)
    
    print(f"   Training Accuracy: {train_accuracy * 100:.2f}%")
    print(f"   Test Accuracy: {test_accuracy * 100:.2f}%")
    
    # Detailed classification report
    print("\n📋 Classification Report (Test Set):")
    print(classification_report(
        y_test, y_pred,
        target_names=['GREEN', 'YELLOW', 'ORANGE', 'RED']
    ))
    
    # Confusion matrix
    print("\n🎯 Confusion Matrix:")
    cm = confusion_matrix(y_test, y_pred)
    print(cm)
    
    # Feature importance
    print("\n⚙️  Feature Importance (Top 10):")
    feature_names = [f"q{i+1}" for i in range(12)] + \
                   ['systolic_dev', 'diastolic_dev', 'glucose_dev', 'medication', 'condition', 'age']
    importances = model.feature_importances_
    indices = np.argsort(importances)[::-1][:10]
    for rank, idx in enumerate(indices, 1):
        print(f"   {rank:2d}. {feature_names[idx]:15s}: {importances[idx]:.4f}")
    
    return model, test_accuracy


def save_model(model, accuracy):
    """Save trained model to disk"""
    print("\n💾 Saving model...")
    
    model_dir = os.path.join(os.path.dirname(__file__), 'ml_models')
    os.makedirs(model_dir, exist_ok=True)
    
    # Save as v2 (new version with 12 questions)
    model_path_v2 = os.path.join(model_dir, 'risk_model_v2.pkl')
    
    with open(model_path_v2, 'wb') as f:
        pickle.dump(model, f)
    print(f"   ✅ Saved to: {model_path_v2}")
    
    # Also save as main model (overwrite)
    # Uncomment below to make v2 the default model
    # model_path = os.path.join(model_dir, 'risk_model.pkl')
    # with open(model_path, 'wb') as f:
    #     pickle.dump(model, f)
    # print(f"   ✅ Also saved as: {model_path}")
    
    # Save model metadata
    metadata = {
        'version': '2.0',
        'features': 19,
        'description': '12-question risk model with baseline data integration',
        'accuracy': accuracy,
        'feature_names': [f"q{i+1}" for i in range(12)] + \
                        ['systolic_dev', 'diastolic_dev', 'glucose_dev', 'medication', 'condition', 'age'],
        'classes': {0: 'GREEN', 1: 'YELLOW', 2: 'ORANGE', 3: 'RED'},
    }
    
    metadata_path = os.path.join(model_dir, 'model_metadata_v2.pkl')
    with open(metadata_path, 'wb') as f:
        pickle.dump(metadata, f)
    print(f"   ✅ Metadata saved to: {metadata_path}")


if __name__ == '__main__':
    try:
        # Train model
        model, accuracy = train_model()
        
        # Save model
        save_model(model, accuracy)
        
        print("\n" + "=" * 70)
        print("✨ Model training complete!")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ Error during training: {e}")
        import traceback
        traceback.print_exc()
