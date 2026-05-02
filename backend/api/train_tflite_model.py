"""
TFLite Model Training Script — Health Tracker System

Trains a Keras dense neural network on the same 74k clinical records used
for the Random Forest, then converts it to TFLite format for on-device
inference in the Flutter mobile app.

Requires: tensorflow, scikit-learn, pandas, numpy (already in requirements.txt
except tensorflow — install locally with: pip install tensorflow)

Input:  backend/api/ml_models/nhanes_data/ (same 3 CSV files)
Output: backend/api/ml_models/risk_model.tflite  (~50–150 KB after quantization)

Feature vector (18 features — same as RF model):
  [q1..q12 (symptom scores 0-3), systolic_dev, diastolic_dev, glucose_dev,
   medication_adherence (0/1), condition_code (0/1/2), age_normalized (0-1)]

Labels: 0=GREEN, 1=YELLOW, 2=ORANGE, 3=RED
"""
import os
import sys

# Allow importing load_clinical_data from train_model.py in the same directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from train_model import load_clinical_data


def train_and_export():
    print("=" * 65)
    print("🧠 TFLite Model Training — Health Tracker (Keras → TFLite)")
    print("=" * 65)

    # ── 1. Load the same clinical data used for the RF ──────────────────
    print("\n📊 Loading clinical data (same 74k records as RF model)...")
    X, y = load_clinical_data()
    n_features = X.shape[1]  # 18
    print(f"   {len(X):,} balanced samples, {n_features} features")

    # ── 2. Import TensorFlow ─────────────────────────────────────────────
    try:
        import tensorflow as tf
    except ImportError:
        print("\n❌ TensorFlow not found. Install with:")
        print("   pip install tensorflow")
        sys.exit(1)

    from sklearn.model_selection import train_test_split

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    y_train_oh = tf.keras.utils.to_categorical(y_train, 4)
    y_test_oh  = tf.keras.utils.to_categorical(y_test,  4)

    # ── 3. Build model ───────────────────────────────────────────────────
    print("\n🏗️  Building Keras model...")
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(n_features,)),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(4, activation='softmax'),
    ], name='risk_classifier')

    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy'],
    )
    model.summary()

    # ── 4. Train ─────────────────────────────────────────────────────────
    print("\n🏋️  Training (30 epochs)...")
    history = model.fit(
        X_train, y_train_oh,
        epochs=30,
        batch_size=256,
        validation_data=(X_test, y_test_oh),
        verbose=1,
    )

    best_val_acc = max(history.history['val_accuracy'])
    print(f"\n✅ Best validation accuracy: {best_val_acc * 100:.2f}%")

    # Evaluate on test set
    loss, acc = model.evaluate(X_test, y_test_oh, verbose=0)
    print(f"   Final test accuracy: {acc * 100:.2f}%")

    # ── 5. Convert to TFLite with float16 quantization ───────────────────
    print("\n📦 Converting to TFLite (float16 quantization)...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    # ── 6. Save ───────────────────────────────────────────────────────────
    out_dir  = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml_models')
    out_path = os.path.join(out_dir, 'risk_model.tflite')
    with open(out_path, 'wb') as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"\n✅ Saved: {out_path}")
    print(f"   File size: {size_kb:.1f} KB")

    # ── 7. Quick sanity check ─────────────────────────────────────────────
    print("\n🔍 Sanity-checking TFLite model...")
    interp = tf.lite.Interpreter(model_path=out_path)
    interp.allocate_tensors()
    inp_det = interp.get_input_details()
    out_det = interp.get_output_details()
    print(f"   Input  shape: {inp_det[0]['shape']}  dtype: {inp_det[0]['dtype']}")
    print(f"   Output shape: {out_det[0]['shape']}  dtype: {out_det[0]['dtype']}")

    import numpy as np
    test_input = np.zeros((1, n_features), dtype=np.float32)
    interp.set_tensor(inp_det[0]['index'], test_input)
    interp.invoke()
    out = interp.get_tensor(out_det[0]['index'])
    print(f"   Test prediction (all-zero input): {out[0]}")

    print("\n" + "=" * 65)
    print("✨ TFLite model ready!")
    print(f"   Copy {out_path}")
    print("   to: mobile/assets/ml_models/risk_model.tflite")
    print("=" * 65)
    return out_path


if __name__ == '__main__':
    train_and_export()
