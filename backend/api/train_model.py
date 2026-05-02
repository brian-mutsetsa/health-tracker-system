"""
ML Model Training Script for Health Tracker System
Trains Random Forest classifier for risk prediction using real clinical datasets:

  - Cardiovascular Disease Dataset (Kaggle/Ulianova) — 70,000 records
      cardio_train.csv  (semicolon-delimited)
      Columns: age(days), ap_hi, ap_lo, gluc, active, cardio

  - Pima Indians Diabetes Dataset (UCI / Kaggle) — 768 records
      diabetes.csv
      Columns: Glucose, BloodPressure, Age, Outcome

  - Stroke Prediction Dataset (Kaggle/fedesoriano) — 5,110 records
      healthcare-dataset-stroke-data.csv
      Columns: age, hypertension, avg_glucose_level, bmi, stroke

Risk labels are derived from established clinical thresholds:
  GREEN  (0) — Normal: BP <120/80 AND glucose <100 mg/dL AND no disease flag
  YELLOW (1) — Elevated: BP 120-139/80-89 OR glucose 100-125 OR mild disease risk
  ORANGE (2) — Stage 1 high: BP 140-159/90-99 OR glucose 126-199 OR disease present
  RED    (3) — Stage 2 crisis: BP ≥160/100 OR glucose ≥200 OR severe disease

Feature vector (19 features, same structure as views.py expects):
  [q1..q12 (symptom scores 0-3), systolic_dev, diastolic_dev, glucose_dev,
   medication_adherence, condition_code, age_normalized]

Output: risk_model_v2.pkl saved to ml_models/
"""
import pickle
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.utils import resample
import os
import random

random.seed(42)
np.random.seed(42)

DATA_DIR = os.path.join(os.path.dirname(__file__), 'ml_models', 'nhanes_data')


def _bp_risk(systolic, diastolic):
    """Return 0-3 risk level from JNC 8 / ACC/AHA 2017 BP thresholds."""
    if systolic >= 160 or diastolic >= 100:
        return 3  # RED — Stage 2 hypertension / hypertensive crisis
    elif systolic >= 140 or diastolic >= 90:
        return 2  # ORANGE — Stage 1 hypertension
    elif systolic >= 120:
        return 1  # YELLOW — Elevated / prehypertension
    else:
        return 0  # GREEN — Normal


def _glucose_risk(glucose_mgdl):
    """Return 0-3 risk level from ADA fasting glucose thresholds."""
    if glucose_mgdl >= 200:
        return 3  # RED — Diabetic crisis
    elif glucose_mgdl >= 126:
        return 2  # ORANGE — Diabetes range
    elif glucose_mgdl >= 100:
        return 1  # YELLOW — Prediabetes
    else:
        return 0  # GREEN — Normal


def _derive_symptom_scores(risk_level, active, rng):
    """
    Derive 12 symptom scores (0-3) from a clinical risk level and activity flag.
    Scores are stochastically assigned so the model learns a distribution,
    not a perfect mapping — mimicking real patient self-reporting variability.

    Questions (app order):
      q1  headache/dizziness          — elevated for hypertension
      q2  chest pain/tightness        — elevated for cardiovascular
      q3  shortness of breath         — elevated for cardiovascular/high BP
      q4  fatigue/weakness            — elevated for all conditions at high risk
      q5  excessive thirst/dry mouth  — elevated for diabetes
      q6  frequent urination          — elevated for diabetes
      q7  blurred vision              — elevated for diabetes & high BP
      q8  nausea/vomiting             — elevated at RED
      q9  swelling (legs/ankles)      — elevated for cardiovascular
      q10 irregular heartbeat         — elevated for cardiovascular
      q11 physical activity level     — INVERTED (higher activity = lower score)
      q12 medication adherence        — 0=taken(low score), 3=missed(high score)
    """
    base = risk_level  # 0-3 base severity
    noise = lambda lo, hi: int(np.clip(rng.integers(lo, hi + 1), 0, 3))

    q1  = noise(max(0, base - 1), min(3, base + 1))
    q2  = noise(max(0, base - 1), min(3, base + 1))
    q3  = noise(max(0, base - 1), min(3, base + 1))
    q4  = noise(max(0, base - 1), min(3, base + 1))
    q5  = noise(max(0, base - 1), min(3, base + 1))
    q6  = noise(max(0, base - 1), min(3, base + 1))
    q7  = noise(max(0, base - 1), min(3, base + 1))
    q8  = noise(max(0, base - 1), min(3, base + 1))
    q9  = noise(max(0, base - 1), min(3, base + 1))
    q10 = noise(max(0, base - 1), min(3, base + 1))
    # q11: physical activity inverted — active=1 → lower score
    q11 = 0 if active else noise(1, 3)
    # q12: medication adherence — higher risk = more likely missed meds
    q12 = 0 if (risk_level == 0 or rng.random() > 0.4 * risk_level / 3) else noise(1, 3)

    return [q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12]


def load_cardiovascular_data(rng):
    """
    Load cardio_train.csv — condition_code = 2 (Cardiovascular).
    Semicolon-delimited. age is in days → convert to years.
    """
    path = os.path.join(DATA_DIR, 'cardio_train.csv')
    df = pd.read_csv(path, sep=';')
    df = df.dropna(subset=['ap_hi', 'ap_lo', 'gluc', 'age', 'active', 'cardio'])

    # Remove physiologically impossible BP readings
    df = df[(df['ap_hi'] >= 70) & (df['ap_hi'] <= 250)]
    df = df[(df['ap_lo'] >= 40) & (df['ap_lo'] <= 150)]

    rows = []
    for _, r in df.iterrows():
        age_years = r['age'] / 365.25
        systolic = float(r['ap_hi'])
        diastolic = float(r['ap_lo'])
        # gluc: 1=normal(<100), 2=above normal(100-125), 3=well above(≥126)
        glucose_approx = {1: 85.0, 2: 112.0, 3: 160.0}.get(int(r['gluc']), 85.0)
        active = int(r['active'])
        has_cardio = int(r['cardio'])

        # Derive risk from BP + glucose + disease flag
        bp_r = _bp_risk(systolic, diastolic)
        gl_r = _glucose_risk(glucose_approx)
        disease_bonus = 1 if has_cardio else 0
        risk = min(3, max(bp_r, gl_r) + disease_bonus)

        # Baselines: use population averages as reference point
        baseline_systolic = 120.0
        baseline_diastolic = 80.0
        baseline_glucose = 100.0

        symptom_scores = _derive_symptom_scores(risk, active, rng)
        medication_adherence = 1 if (risk <= 1 or rng.random() > 0.35) else 0
        age_normalized = (age_years - 25.0) / 60.0

        features = symptom_scores + [
            systolic - baseline_systolic,
            diastolic - baseline_diastolic,
            glucose_approx - baseline_glucose,
            medication_adherence,
            2,  # condition_code = Cardiovascular
            float(np.clip(age_normalized, 0.0, 1.0)),
        ]
        rows.append((features, risk))

    print(f"   Cardiovascular dataset: {len(rows)} records loaded")
    return rows


def load_diabetes_data(rng):
    """
    Load diabetes.csv — condition_code = 1 (Diabetes).
    BloodPressure is diastolic only; systolic estimated.
    """
    path = os.path.join(DATA_DIR, 'diabetes.csv')
    df = pd.read_csv(path)
    df = df.dropna(subset=['Glucose', 'BloodPressure', 'Age', 'Outcome'])
    # Remove zero-value placeholders
    df = df[(df['Glucose'] > 0) & (df['BloodPressure'] > 0)]

    rows = []
    for _, r in df.iterrows():
        age_years = float(r['Age'])
        glucose = float(r['Glucose'])
        diastolic = float(r['BloodPressure'])
        # Estimate systolic from diastolic using typical pulse pressure (~40 mmHg)
        systolic = diastolic + 40.0
        has_diabetes = int(r['Outcome'])
        active = 1 if rng.random() > 0.4 else 0  # not in dataset, sample reasonably

        bp_r = _bp_risk(systolic, diastolic)
        gl_r = _glucose_risk(glucose)
        disease_bonus = 1 if has_diabetes else 0
        risk = min(3, max(bp_r, gl_r) + disease_bonus)

        baseline_systolic = 120.0
        baseline_diastolic = 80.0
        baseline_glucose = 100.0

        symptom_scores = _derive_symptom_scores(risk, active, rng)
        medication_adherence = 1 if (risk <= 1 or rng.random() > 0.35) else 0
        age_normalized = float(np.clip((age_years - 25.0) / 60.0, 0.0, 1.0))

        features = symptom_scores + [
            systolic - baseline_systolic,
            diastolic - baseline_diastolic,
            glucose - baseline_glucose,
            medication_adherence,
            1,  # condition_code = Diabetes
            age_normalized,
        ]
        rows.append((features, risk))

    print(f"   Diabetes dataset: {len(rows)} records loaded")
    return rows


def load_hypertension_data(rng):
    """
    Load healthcare-dataset-stroke-data.csv — condition_code = 0 (Hypertension).
    avg_glucose_level is post-meal so thresholds are shifted up ~40 mg/dL.
    """
    path = os.path.join(DATA_DIR, 'healthcare-dataset-stroke-data.csv')
    df = pd.read_csv(path)
    df = df.dropna(subset=['age', 'avg_glucose_level', 'hypertension', 'heart_disease'])

    rows = []
    for _, r in df.iterrows():
        age_years = float(r['age'])
        glucose_postmeal = float(r['avg_glucose_level'])
        # Convert post-meal glucose to approximate fasting equivalent
        glucose_fasting = glucose_postmeal * 0.75
        has_hypertension = int(r['hypertension'])
        has_heart_disease = int(r['heart_disease'])
        active = 1 if rng.random() > 0.4 else 0

        # Estimate BP from hypertension flag and age
        if has_hypertension:
            systolic = float(rng.integers(140, 175))
            diastolic = float(rng.integers(88, 105))
        else:
            systolic = float(rng.integers(100, 135))
            diastolic = float(rng.integers(65, 85))

        bp_r = _bp_risk(systolic, diastolic)
        gl_r = _glucose_risk(glucose_fasting)
        disease_bonus = 1 if (has_hypertension or has_heart_disease) else 0
        risk = min(3, max(bp_r, gl_r) + disease_bonus)

        baseline_systolic = 120.0
        baseline_diastolic = 80.0
        baseline_glucose = 100.0

        symptom_scores = _derive_symptom_scores(risk, active, rng)
        medication_adherence = 1 if (risk <= 1 or rng.random() > 0.35) else 0
        age_normalized = float(np.clip((age_years - 25.0) / 60.0, 0.0, 1.0))

        features = symptom_scores + [
            systolic - baseline_systolic,
            diastolic - baseline_diastolic,
            glucose_fasting - baseline_glucose,
            medication_adherence,
            0,  # condition_code = Hypertension
            age_normalized,
        ]
        rows.append((features, risk))

    print(f"   Hypertension/Stroke dataset: {len(rows)} records loaded")
    return rows


def load_clinical_data():
    """
    Load, combine, and balance all three clinical datasets.
    Returns X (n_samples, 19) and y (n_samples,) arrays.
    """
    rng = np.random.default_rng(42)

    print("\n   Loading clinical datasets...")
    cardio_rows = load_cardiovascular_data(rng)
    diabetes_rows = load_diabetes_data(rng)
    hypertension_rows = load_hypertension_data(rng)

    all_rows = cardio_rows + diabetes_rows + hypertension_rows
    print(f"\n   Total records before balancing: {len(all_rows)}")

    X_raw = np.array([r[0] for r in all_rows], dtype=np.float32)
    y_raw = np.array([r[1] for r in all_rows], dtype=np.int32)

    # Balance classes by upsampling minority classes to match the largest class
    unique, counts = np.unique(y_raw, return_counts=True)
    max_count = counts.max()
    X_balanced, y_balanced = [], []
    for cls in unique:
        mask = y_raw == cls
        X_cls = X_raw[mask]
        y_cls = y_raw[mask]
        if len(X_cls) < max_count:
            X_cls, y_cls = resample(X_cls, y_cls, n_samples=max_count, random_state=42)
        X_balanced.append(X_cls)
        y_balanced.append(y_cls)

    X = np.vstack(X_balanced)
    y = np.concatenate(y_balanced)

    # Shuffle
    idx = np.random.permutation(len(X))
    return X[idx], y[idx]


def train_model():
    """Train and evaluate the Random Forest model"""

    print("=" * 70)
    print("🚀 Health Tracker ML Model Training — Clinical Dataset Edition")
    print("   Cardiovascular Disease (Kaggle/Ulianova) +")
    print("   Pima Indians Diabetes (UCI) +")
    print("   Stroke Prediction / Hypertension (Kaggle/fedesoriano)")
    print("=" * 70)

    # Load real clinical data
    print("\n📊 Loading and processing clinical datasets...")
    X, y = load_clinical_data()
    print(f"\n   Final dataset: {len(X)} balanced samples, {X.shape[1]} features")
    
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
        'version': '3.0',
        'features': 19,
        'description': 'Random Forest trained on real clinical data: Cardiovascular Disease Dataset (70k), Pima Indians Diabetes (768), Stroke/Hypertension Dataset (5,110). Labels derived from JNC 8 BP thresholds and ADA glucose thresholds.',
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
