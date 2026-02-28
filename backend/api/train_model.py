import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import os

# Sample training data (symptom patterns)
# Format: [severe_count, mild_count, none_count, took_medication, condition_code]
# condition_code: 0=Hypertension, 1=Diabetes, 2=Heart Disease
# Labels: 0=GREEN, 1=YELLOW, 2=ORANGE, 3=RED

training_data = [
    # GREEN cases (took meds, mostly "none")
    [0, 0, 7, 1, 0, 0],  # Hypertension, all none, took meds
    [0, 1, 6, 1, 0, 0],  # Hypertension, 1 mild, took meds
    [0, 0, 7, 1, 1, 0],  # Diabetes, all none, took meds
    [0, 1, 6, 1, 1, 0],  # Diabetes, 1 mild, took meds
    [0, 0, 7, 1, 2, 0],  # Heart Disease, all none, took meds
    [0, 1, 6, 1, 2, 0],  # Heart Disease, 1 mild, took meds
    
    # More GREEN variations
    [0, 0, 6, 1, 0, 0],
    [0, 1, 5, 1, 1, 0],
    [0, 0, 6, 1, 2, 0],
    [0, 2, 5, 1, 0, 0],
    
    # YELLOW cases (1 severe OR 3+ mild OR missed meds)
    [1, 0, 6, 1, 0, 1],  # Hypertension, 1 severe
    [0, 3, 4, 1, 0, 1],  # Hypertension, 3 mild
    [0, 1, 6, 0, 0, 1],  # Hypertension, missed meds
    [1, 0, 6, 1, 1, 1],  # Diabetes, 1 severe
    [0, 4, 3, 1, 1, 1],  # Diabetes, 4 mild
    [0, 2, 5, 0, 1, 1],  # Diabetes, missed meds
    [1, 0, 6, 1, 2, 1],  # Heart Disease, 1 severe
    [0, 3, 4, 1, 2, 1],  # Heart Disease, 3 mild
    [0, 1, 6, 0, 2, 1],  # Heart Disease, missed meds
    
    # More YELLOW variations
    [1, 1, 5, 1, 0, 1],
    [0, 4, 3, 1, 2, 1],
    [1, 0, 5, 0, 1, 1],
    [0, 3, 3, 0, 0, 1],
    
    # ORANGE cases (2+ severe OR severe + missed meds)
    [2, 0, 5, 1, 0, 2],  # Hypertension, 2 severe
    [1, 2, 4, 0, 0, 2],  # Hypertension, 1 severe + missed meds
    [2, 1, 4, 1, 1, 2],  # Diabetes, 2 severe
    [1, 3, 3, 0, 1, 2],  # Diabetes, 1 severe + 3 mild + no meds
    [2, 0, 5, 1, 2, 2],  # Heart Disease, 2 severe
    [1, 1, 5, 0, 2, 2],  # Heart Disease, 1 severe + missed meds
    
    # More ORANGE variations
    [2, 2, 3, 1, 0, 2],
    [3, 0, 4, 1, 1, 2],
    [2, 1, 4, 0, 2, 2],
    [1, 4, 2, 0, 0, 2],
    
    # RED cases (3+ severe OR critical combinations)
    [3, 0, 4, 1, 0, 3],  # Hypertension, 3 severe
    [4, 1, 2, 0, 0, 3],  # Hypertension, 4 severe + no meds
    [3, 2, 2, 1, 1, 3],  # Diabetes, 3 severe
    [5, 0, 2, 0, 1, 3],  # Diabetes, 5 severe + no meds
    [3, 0, 4, 1, 2, 3],  # Heart Disease, 3 severe (chest pain critical!)
    [4, 2, 1, 0, 2, 3],  # Heart Disease, 4 severe + no meds
    
    # More RED variations
    [3, 3, 1, 1, 0, 3],
    [5, 1, 1, 1, 1, 3],
    [4, 0, 3, 0, 2, 3],
    [6, 0, 1, 1, 0, 3],
]

# Separate features and labels
X = np.array([row[:5] for row in training_data])  # Features
y = np.array([row[5] for row in training_data])   # Labels

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
print("Training ML model...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Test model
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"\n✅ Model trained successfully!")
print(f"📊 Accuracy: {accuracy * 100:.2f}%")
print(f"\n📋 Classification Report:")
print(classification_report(y_test, y_pred, target_names=['GREEN', 'YELLOW', 'ORANGE', 'RED']))

# Save model
model_dir = os.path.join(os.path.dirname(__file__), 'ml_models')
os.makedirs(model_dir, exist_ok=True)
model_path = os.path.join(model_dir, 'risk_model.pkl')

with open(model_path, 'wb') as f:
    pickle.dump(model, f)

print(f"\n💾 Model saved to: {model_path}")